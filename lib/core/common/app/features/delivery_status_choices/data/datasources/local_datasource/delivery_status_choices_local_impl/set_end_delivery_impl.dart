import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/local_datasource/delivery_status_choices_local_impl/delivery_status_choices_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../enums/invoice_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/data/model/user_performance_model.dart';

mixin SetEndDeliveryImpl on DeliveryStatusChoicesLocalBase {
  Future<void> setEndDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '💾 LOCAL: Processing delivery completion for delivery: ${deliveryData.id}',
      );

      // 0️⃣ Validate deliveryData ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const CacheException(message: 'Invalid delivery data ID');
      }

      // 1️⃣ Resolve DeliveryData locally
      final localDeliveryData =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(deliveryDataId))
              .build()
              .findFirst();

      if (localDeliveryData == null) {
        throw const CacheException(message: 'DeliveryData not found locally');
      }

      debugPrint(
        '✅ LOCAL: DeliveryData resolved → OBX ID: ${localDeliveryData.objectBoxId}',
      );

      // 2️⃣ Resolve Trip (single source of truth)
      final tripId =
          deliveryData.trip.target?.id ?? localDeliveryData.trip.target?.id;
      TripModel? tripModel;

      if (tripId != null && tripId.isNotEmpty) {
        final tripQuery =
            objectBoxStore.tripBox.query(TripModel_.id.equals(tripId)).build();
        tripModel = tripQuery.findFirst();
        tripQuery.close();
        debugPrint(
          tripModel != null
              ? '🚛 LOCAL: Trip resolved → OBX ID: ${tripModel.objectBoxId}'
              : '⚠️ LOCAL: Trip not found locally for ID: $tripId',
        );
      } else {
        debugPrint('⚠️ LOCAL: Trip ID missing for delivery data');
      }

      // 3️⃣ Resolve "End Delivery" status
      final endStatus =
          deliveryStatusChoicesBox
              .query(DeliveryStatusChoicesModel_.title.equals('End Delivery'))
              .build()
              .findFirst();

      final endStatusResolved =
          endStatus ??
          deliveryStatusChoicesBox.getAll().firstWhere(
            (s) => s.title?.toLowerCase() == 'end delivery',
            orElse:
                () => DeliveryStatusChoicesModel(
                  id: 'end-delivery-local',
                  title: 'End Delivery',
                  subtitle: 'Delivery Completed',
                ),
          );

      // 4️⃣ Create DeliveryUpdate (End Delivery)
      // NOTE: Collection creation has been moved to createDeliveryReceipt
      // in the delivery receipt datasources. It is no longer created here.
      final now = DateTime.now();

      // 5️⃣ Create DeliveryUpdate (End Delivery)
      final adjustedTime = now.add(const Duration(minutes: 1));
      final deliveryUpdate = DeliveryUpdateModel(
        title: endStatusResolved.title ?? 'End Delivery',
        subtitle: endStatusResolved.subtitle ?? 'Delivery Completed',
        time: adjustedTime,
        created: now,
        updated: now,
        isAssigned: true,
        deliveryDataPbId: deliveryDataId,
        statusChoicePbId: endStatusResolved.id,
        syncStatus: SyncStatus.pending.name,
        retryCount: 0,
      );

      deliveryUpdate.deliveryData.target = localDeliveryData;
      localDeliveryData.deliveryUpdates.add(deliveryUpdate);

      deliveryUpdateBox.put(deliveryUpdate);
      deliveryDataBox.put(localDeliveryData);

      debugPrint('✅ LOCAL: DeliveryUpdate created → ${deliveryUpdate.title}');

      // ---------------------------------------------------
      // 6️⃣ Update User Performance (BEST-EFFORT / NON-BLOCKING)
      // ---------------------------------------------------
      try {
        final user = tripModel?.user.target;

        if (user == null) {
          debugPrint(
            '⚠️ LOCAL: Trip user not resolved, skipping UserPerformance update',
          );
        } else {
          final userPerfBox = objectBoxStore.store.box<UserPerformanceModel>();

          final perfQuery =
              userPerfBox
                  .query(UserPerformanceModel_.user.equals(user.objectBoxId))
                  .build();

          final perf = perfQuery.findFirst();
          perfQuery.close();

          if (perf == null) {
            debugPrint(
              '⚠️ LOCAL: No UserPerformance found for user OBX: ${user.objectBoxId}',
            );
          } else {
            final total = perf.totalDeliveries ?? 0;
            final success = perf.successfulDeliveries ?? 0;

            final newTotal = total + 1;
            final newSuccess = success + 1;

            perf
              ..totalDeliveries = newTotal
              ..successfulDeliveries = newSuccess
              ..deliveryAccuracy = (newSuccess / newTotal) * 100
              ..updated = now
              ..lastLocalUpdatedAt = now.toUtc()
              ..syncStatus = SyncStatus.pending.name
              ..version += 1;

            userPerfBox.put(perf);

            debugPrint(
              '✅ LOCAL: UserPerformance updated\n'
              '   User OBX: ${user.objectBoxId}\n'
              '   Total: $total → $newTotal\n'
              '   Success: $success → $newSuccess\n'
              '   Accuracy: ${perf.deliveryAccuracy?.toStringAsFixed(2)}%',
            );
          }
        }
      } catch (e, st) {
        // ❗ NEVER block delivery completion
        debugPrint(
          '⚠️ LOCAL: UserPerformance update failed (ignored) → $e\n$st',
        );
      }

      // ---------------------------------------------------
      // 7️⃣ Update Delivery Team stats (USING TRIP-FIRST LOGIC)
      // ---------------------------------------------------
      try {
        if (tripId == null || tripId.isEmpty) {
          debugPrint(
            '⚠️ LOCAL: Trip PB ID missing, skipping DeliveryTeam update',
          );
        } else {
          // ✅ 1️⃣ Resolve DeliveryTeam USING THE SAME PATTERN
          DeliveryTeamModel? team;

          final tripQuery =
              objectBoxStore.tripBox
                  .query(TripModel_.id.equals(tripId))
                  .build();
          final trip = tripQuery.findFirst();
          tripQuery.close();

          if (trip == null) {
            debugPrint(
              '⚠️ LOCAL: Trip not found, skipping DeliveryTeam update',
            );
          } else {
            for (final t in objectBoxStore.deliveryTeamBox.getAll()) {
              if (t.trip.targetId == trip.objectBoxId) {
                team = t;
                break;
              }
            }

            if (team == null) {
              debugPrint(
                '⚠️ LOCAL: No DeliveryTeam found for Trip OBX: ${trip.objectBoxId}',
              );
            } else {
              final prevActive = team.activeDeliveries ?? 0;
              final prevTotal = team.totalDelivered ?? 0;

              team
                ..activeDeliveries = (prevActive - 1).clamp(0, 999999)
                ..totalDelivered = prevTotal + 1;

              objectBoxStore.deliveryTeamBox.put(team);

              debugPrint(
                '✅ LOCAL: DeliveryTeam updated\n'
                '   Team PB: ${team.id}\n'
                '   Trip OBX: ${trip.objectBoxId}\n'
                '   Active: $prevActive → ${team.activeDeliveries}\n'
                '   Total: $prevTotal → ${team.totalDelivered}',
              );
            }
          }
        }
      } catch (e, st) {
        // ❗ DO NOT BLOCK DELIVERY COMPLETION
        debugPrint('⚠️ LOCAL: DeliveryTeam update failed (ignored) → $e\n$st');
      }

      // 8️⃣ Update DeliveryData invoice status
      localDeliveryData
        ..invoiceStatus = InvoiceStatus.delivered
        ..updated = now;
      deliveryDataBox.put(localDeliveryData);

      debugPrint(
        '✅ LOCAL: Delivery completed successfully → DeliveryData OBX ID: ${localDeliveryData.objectBoxId}',
      );
    } catch (e, st) {
      debugPrint('❌ LOCAL: CompleteDelivery failed → $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
