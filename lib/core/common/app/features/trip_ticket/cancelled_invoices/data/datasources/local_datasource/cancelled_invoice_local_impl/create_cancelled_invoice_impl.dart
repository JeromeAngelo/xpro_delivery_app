import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../delivery_team/delivery_team/data/models/delivery_team_model.dart';
import '../../../../../../users/user_performance/data/model/user_performance_model.dart';

mixin CreateCancelledInvoiceImpl on CancelledInvoiceLocalBase {
  Future<CancelledInvoiceModel> createCancelledInvoice(
    CancelledInvoiceModel input,
    String deliveryDataId,
  ) async {
    try {
      debugPrint('📱 LOCAL: Creating cancelled invoice (offline-first)');

      final now = DateTime.now();

      // 0️⃣ Validate deliveryData ID
      if (deliveryDataId.isEmpty) {
        throw const CacheException(message: 'Invalid delivery data ID');
      }

      // 1️⃣ Resolve DeliveryData LOCALLY
      final deliveryQuery =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build();

      final localDeliveryData = deliveryQuery.findFirst();
      deliveryQuery.close();

      if (localDeliveryData == null) {
        throw const CacheException(message: 'DeliveryData not found locally');
      }

      debugPrint(
        '✅ LOCAL: DeliveryData resolved → OBX: ${localDeliveryData.objectBoxId}',
      );

      // 2️⃣ Resolve Trip (if exists)
      TripModel? tripModel;
      final tripPbId =
          localDeliveryData.trip.target?.id ??
          localDeliveryData.trip.target?.pocketbaseId;

      if (tripPbId != null && tripPbId.isNotEmpty) {
        final tripQuery =
            objectBoxStore.tripBox
                .query(TripModel_.id.equals(tripPbId))
                .build();
        tripModel = tripQuery.findFirst();
        tripQuery.close();

        debugPrint(
          tripModel != null
              ? '🚛 LOCAL: Trip resolved → OBX: ${tripModel.objectBoxId}'
              : '⚠️ LOCAL: Trip not found for PB ID: $tripPbId',
        );
      } else {
        debugPrint('⚠️ LOCAL: Trip ID missing on DeliveryData');
      }

      final model = CancelledInvoiceModel(
        id: null,
        deliveryDataId: localDeliveryData.pocketbaseId,
        tripId: tripModel?.pocketbaseId,
        deliveryDataModel: localDeliveryData,
        tripModel: tripModel,
        reasonString:
            input.reason?.name ?? UndeliverableReason.storeClosed.name,
        reason: input.reason ?? UndeliverableReason.storeClosed,
        image: input.image,
        created: input.created ?? now,
        updated: now,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
        lastSyncAttemptAt: now,
        lastLocalUpdatedAt: now,
      );

      final obxId = cancelledInvoiceBox.put(model);
      model.objectBoxId = obxId;

      model.deliveryData
        ..targetId = localDeliveryData.objectBoxId
        ..target = localDeliveryData;

      if (tripModel != null) {
        model.trip
          ..targetId = tripModel.objectBoxId
          ..target = tripModel;
      }

      debugPrint(
        '✅ LOCAL: CancelledInvoice saved → OBX:$obxId | PB:${model.id} | reason :${model.reason} or reasonString: ${model.reasonString}',
      );

      // 6️⃣ LINK → Trip (ToMany)
      if (tripModel != null) {
        await linkCancelledInvoiceToTrip(tripModel, model);
      }

      // 6️⃣ Update UserPerformance (undelivered)
      try {
        final user = tripModel?.user.target;
        if (user != null) {
          final userPerfBox = objectBoxStore.store.box<UserPerformanceModel>();
          final perfQuery =
              userPerfBox
                  .query(UserPerformanceModel_.user.equals(user.objectBoxId))
                  .build();
          final perf = perfQuery.findFirst();
          perfQuery.close();

          if (perf != null) {
            final prevCancelled = perf.cancelledDeliveries ?? 0;
            perf
              ..cancelledDeliveries = prevCancelled + 1
              ..updated = now
              ..lastLocalUpdatedAt = now.toUtc()
              ..syncStatus = SyncStatus.pending.name
              ..version += 1;

            userPerfBox.put(perf);
            debugPrint(
              '✅ LOCAL: UserPerformance updated → Cancelled: $prevCancelled → ${perf.cancelledDeliveries}',
            );
          } else {
            debugPrint(
              '⚠️ LOCAL: No UserPerformance found for user OBX: ${user.objectBoxId}',
            );
          }
        } else {
          debugPrint('⚠️ LOCAL: User not resolved, skipping UserPerformance');
        }
      } catch (e, st) {
        debugPrint(
          '⚠️ LOCAL: UserPerformance update failed (ignored)\n$e\n$st',
        );
      }

      // 7️⃣ Update DeliveryTeam (undelivered)
      try {
        if (tripModel != null) {
          DeliveryTeamModel? team;
          for (final t in objectBoxStore.deliveryTeamBox.getAll()) {
            if (t.trip.targetId == tripModel.objectBoxId) {
              team = t;
              break;
            }
          }

          if (team != null) {
            final prevActive = team.activeDeliveries ?? 0;
            final prevUndelivered = team.undeliveredCustomers ?? 0;
            team
              ..activeDeliveries = (prevActive - 1).clamp(0, 999999)
              ..undeliveredCustomers = prevUndelivered + 1;

            objectBoxStore.deliveryTeamBox.put(team);
            debugPrint(
              '✅ LOCAL: DeliveryTeam updated → Active: $prevActive → ${team.activeDeliveries}, Undelivered: $prevUndelivered → ${team.undeliveredCustomers}',
            );
          } else {
            debugPrint(
              '⚠️ LOCAL: No DeliveryTeam found for Trip OBX: ${tripModel.objectBoxId}',
            );
          }
        }
      } catch (e, st) {
        debugPrint('⚠️ LOCAL: DeliveryTeam update failed (ignored)\n$e\n$st');
      }

      return model;
    } catch (e, st) {
      debugPrint('❌ LOCAL createCancelledInvoice ERROR:\n$e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
