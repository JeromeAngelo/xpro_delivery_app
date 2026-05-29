import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin ForceReloadLocalUserTripImpl on AuthLocalBase {
  Future<TripModel> forceReloadLocalUserTrip(String userId) async {
    try {
      debugPrint('🔁 LOCAL: Force reloading FULL trip for user=$userId');

      final userQuery =
          box.query(LocalUsersModel_.pocketbaseId.equals(userId)).build();
      final user = userQuery.findFirst();
      userQuery.close();

      if (user == null) {
        throw const CacheException(message: 'User not found in local DB');
      }

      final tripRef = user.trip.target;
      if (tripRef == null) {
        throw const CacheException(message: 'No trip assigned to this user');
      }

      final tripObxId = tripRef.objectBoxId;
      if (tripObxId <= 0) {
        debugPrint('⚠️ Trip target exists but has invalid OBX id=$tripObxId');
        throw const CacheException(
          message: 'Trip has invalid local ObjectBox ID',
        );
      }

      final trip = tripBox.get(tripObxId);
      if (trip == null) {
        throw const CacheException(message: 'Trip record missing in DB');
      }

      debugPrint('📦 Trip reloaded → ${trip.name} (OBX: ${trip.objectBoxId})');

      // -----------------------------------------------------
      // 2️⃣ Reload Delivery Team
      // -----------------------------------------------------
      final dtRef = trip.deliveryTeam.target;
      if (dtRef != null && dtRef.objectBoxId > 0) {
        final fullDT = deliveryTeamBox.get(dtRef.objectBoxId);
        if (fullDT != null) {
          trip.deliveryTeam
            ..target = fullDT
            ..targetId = fullDT.objectBoxId;
          debugPrint('👥 DeliveryTeam reloaded → ${fullDT.id}');
        }
      }

      // -----------------------------------------------------
      // 3️⃣ Reload In-Transit OTP
      // -----------------------------------------------------
      final otpRef = trip.otp.target;
      final otpObxId = otpRef?.dbId ?? 0;
      if (otpRef != null && otpObxId > 0) {
        final fullOtp = otpBox.get(otpObxId);
        if (fullOtp != null) {
          trip.otp
            ..target = fullOtp
            ..targetId = fullOtp.dbId;
          debugPrint('🔐 In-transit OTP reloaded → ${fullOtp.id}');
        }
      } else if (otpRef != null) {
        debugPrint('⚠️ OTP target exists but has invalid dbId=$otpObxId');
      }

      // -----------------------------------------------------
      // 4️⃣ Reload End Trip OTP
      // -----------------------------------------------------
      final endOtpRef = trip.endTripOtp.target;
      final endOtpObxId = endOtpRef?.dbId ?? 0;
      if (endOtpRef != null && endOtpObxId > 0) {
        final fullOtp = endTripOtpBox.get(endOtpObxId);
        if (fullOtp != null) {
          trip.endTripOtp
            ..target = fullOtp
            ..targetId = fullOtp.dbId;
          debugPrint('🔐 EndTrip OTP reloaded → ${fullOtp.id}');
        }
      } else if (endOtpRef != null) {
        debugPrint(
          '⚠️ EndTripOtp target exists but has invalid dbId=$endOtpObxId',
        );
      }

      // -----------------------------------------------------
      // 5️⃣ Reload Delivery Data
      // -----------------------------------------------------
      final deliveryList = trip.deliveryData.toList();
      final refreshedDeliveries = <DeliveryDataModel>[];

      for (final d in deliveryList) {
        final id = d.objectBoxId;
        if (id <= 0) {
          debugPrint('⚠️ DeliveryData has invalid OBX id=$id (pbId=${d.id})');
          continue;
        }
        final fullDD = deliveryDataBox.get(id);
        if (fullDD != null) {
          refreshedDeliveries.add(fullDD);
          debugPrint('📦 DeliveryData reloaded → ${fullDD.ownerName}');
        }
      }

      trip.deliveryData
        ..clear()
        ..addAll(refreshedDeliveries);

      // -----------------------------------------------------
      // 6️⃣ Reload End Trip Checklist
      // -----------------------------------------------------
      final checklistList = trip.endTripChecklist.toList();
      final refreshedChecklist = <EndTripChecklistModel>[];

      for (final c in checklistList) {
        final id = c.dbId;
        if (id <= 0) {
          debugPrint('⚠️ EndTripChecklist has invalid dbId=$id (pbId=${c.id})');
          continue;
        }
        final full = endTripChecklistBox.get(id);
        if (full != null) {
          refreshedChecklist.add(full);
          debugPrint('📋 Checklist reloaded → ${full.objectName}');
        }
      }

      trip.endTripChecklist
        ..clear()
        ..addAll(refreshedChecklist);

      // -----------------------------------------------------
      // 7️⃣ Reload Trip Updates  ✅ FIXED
      // -----------------------------------------------------
      final updatesList = trip.tripUpdates.toList();
      final refreshedUpdates = <TripUpdateModel>[];

      debugPrint('🧾 TripUpdates: linkedCount=${updatesList.length}');
      for (final u in updatesList) {
        final id =
            u.dbId; // or u.objectBoxId (use whichever is your OBX id field)
        if (id <= 0) {
          debugPrint(
            '⚠️ TripUpdate has invalid dbId=$id (pbId=${u.id}) — skipping get()',
          );
          continue;
        }

        final full = tripUpdateBox.get(id);
        if (full != null) {
          refreshedUpdates.add(full);
          debugPrint('📋 TripUpdate reloaded → ${full.description}');
        } else {
          debugPrint(
            '⚠️ TripUpdate missing in box for dbId=$id (pbId=${u.id})',
          );
        }
      }

      trip.tripUpdates
        ..clear()
        ..addAll(refreshedUpdates);

      // -----------------------------------------------------
      // 8️⃣ Reload Cancelled Invoices
      // -----------------------------------------------------
      final cancelledList = trip.cancelledInvoices.toList();
      final refreshedInvoices = <CancelledInvoiceModel>[];

      for (final i in cancelledList) {
        final id = i.objectBoxId;
        if (id <= 0) {
          debugPrint(
            '⚠️ CancelledInvoice has invalid OBX id=$id (pbId=${i.id})',
          );
          continue;
        }
        final full = cancelledInvoiceBox.get(id);
        if (full != null) {
          refreshedInvoices.add(full);
          debugPrint('📋 CancelledInvoice reloaded → ${full.id}');
        }
      }

      trip.cancelledInvoices
        ..clear()
        ..addAll(refreshedInvoices);

      // -----------------------------------------------------
      // 9️⃣ Reload Delivery Collection
      // -----------------------------------------------------
      final collectionList = trip.deliveryCollection.toList();
      final refreshedCollection = <CollectionModel>[];

      for (final c in collectionList) {
        final id = c.objectBoxId;
        if (id <= 0) {
          debugPrint('⚠️ Collection has invalid OBX id=$id (pbId=${c.id})');
          continue;
        }
        final full = deliveryCollectonBox.get(id);
        if (full != null) {
          refreshedCollection.add(full);
          debugPrint('📋 Collection reloaded → ${full.id}');
        }
      }

      trip.deliveryCollection
        ..clear()
        ..addAll(refreshedCollection);

      tripBox.put(trip);

      debugPrint('✅ LOCAL: Force reload trip COMPLETE');
      debugPrint('   ✅ tripUpdatesReloaded=${refreshedUpdates.length}');
      return trip;
    } catch (e, st) {
      debugPrint('❌ forceReloadLocalUserTrip ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
