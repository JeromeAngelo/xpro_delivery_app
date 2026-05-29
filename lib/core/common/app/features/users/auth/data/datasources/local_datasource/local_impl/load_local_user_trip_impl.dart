import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';

mixin LoadLocalUserTripImpl on AuthLocalBase {
  Future<TripModel> loadLocalUserTrip(String userId) async {
    try {
      debugPrint('LOCAL 🔄 loadLocalUserTrip for user: $userId');

      // 1️⃣ Load User By PB ID
      final user =
          box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      if (user == null) {
        debugPrint('⚠️ User not found in local DB');
        throw const CacheException(message: 'User not found in local DB');
      }

      final trip = user.trip.target;

      if (trip == null) {
        debugPrint('⚠️ No Trip assigned to this user');
        throw const CacheException(message: 'No trip found for this user');
      }

      debugPrint(
        '📦 Trip found → ${trip.name} (OBX: ${trip.objectBoxId}) with delivery data length → ${trip.deliveryData.length}',
      );

      // 2️⃣ Load Delivery Team safely
      final dtRef = trip.deliveryTeam.target;
      if (dtRef != null) {
        final fullDT = deliveryTeamBox.get(dtRef.objectBoxId);
        if (fullDT != null) {
          trip.deliveryTeam.target = fullDT;
          trip.deliveryTeam.targetId = fullDT.objectBoxId;
          debugPrint('👥 Delivery Team loaded → ${fullDT.id}');
        }
      }
      // 2️⃣ Load Delivery Team safely
      final otpRef = trip.otp.target;
      if (otpRef != null) {
        final fullOtp = otpBox.get(otpRef.dbId);
        if (fullOtp != null) {
          trip.otp.target = fullOtp;
          trip.otp.targetId = fullOtp.dbId;
          debugPrint('👥 intransit OTP loaded → ${fullOtp.id}');
        }
      }
      // 2️⃣ Load Delivery Team safely
      final endTripOtpRef = trip.endTripOtp.target;
      if (endTripOtpRef != null) {
        final fullOtp = endTripOtpBox.get(endTripOtpRef.dbId);
        if (fullOtp != null) {
          trip.endTripOtp.target = fullOtp;
          trip.endTripOtp.targetId = fullOtp.dbId;
          debugPrint('👥 end trip OTP loaded → ${fullOtp.id}');
        }
      }

      // 3️⃣ Load Delivery Data safely
      final ddList = trip.deliveryData.toList();
      final cleanedDD = <DeliveryDataModel>[];
      for (var d in ddList) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) {
          cleanedDD.add(fullDD);
          debugPrint(
            '📦 DeliveryData loaded → ${fullDD.ownerName} (OBX: ${fullDD.objectBoxId})',
          );
        }
      }
      trip.deliveryData.clear();
      trip.deliveryData.addAll(cleanedDD);

      // 4️⃣ Load End Trip Checklist safely
      final endChecklists = trip.endTripChecklist.toList();
      final cleanedChecklist = <EndTripChecklistModel>[];
      for (var c in endChecklists) {
        final fullChecklist = endTripChecklistBox.get(c.dbId);
        if (fullChecklist != null) {
          cleanedChecklist.add(fullChecklist);
          debugPrint(
            '📋 EndTrip Checklist loaded → ${fullChecklist.objectName}',
          );
        }
      }
      trip.endTripChecklist.clear();
      trip.endTripChecklist.addAll(cleanedChecklist);

      // 5️⃣ Load Trip Updates safely
      final tripUpdates = trip.tripUpdates.toList();
      final cleanedUpdates = <TripUpdateModel>[];
      for (var u in tripUpdates) {
        final fullUpdate = tripUpdateBox.get(u.dbId);
        if (fullUpdate != null) {
          cleanedUpdates.add(fullUpdate);
          debugPrint('📋 Trip Update loaded → ${fullUpdate.description}');
        }
      }
      trip.tripUpdates.clear();
      trip.tripUpdates.addAll(cleanedUpdates);

      // 6️⃣ Load Cancelled Invoices safely
      final cancelledInvoices = trip.cancelledInvoices.toList();
      final cleanedInvoices = <CancelledInvoiceModel>[];
      for (var i in cancelledInvoices) {
        final fullInvoice = cancelledInvoiceBox.get(i.objectBoxId);
        if (fullInvoice != null) {
          cleanedInvoices.add(fullInvoice);
          debugPrint('📋 Cancelled Invoice loaded → ${fullInvoice.id}');
        }
      }
      trip.cancelledInvoices.clear();
      trip.cancelledInvoices.addAll(cleanedInvoices);

      final deliveryCollection = trip.deliveryCollection.toList();
      final cleanedCollection = <CollectionModel>[];
      for (var c in deliveryCollection) {
        final fullCollection = deliveryCollectonBox.get(c.objectBoxId);
        if (fullCollection != null) {
          cleanedCollection.add(fullCollection);
          debugPrint('📋 Delivery Collection loaded → ${fullCollection.id}');
        }
      }
      trip.deliveryCollection.clear();
      trip.deliveryCollection.addAll(cleanedCollection);

      // 4️⃣ Load intransit Trip Checklist safely
      final intransitChecklist = trip.checklist.toList();
      final cleanedIntransitChecklist = <ChecklistModel>[];
      for (var c in intransitChecklist) {
        final fullChecklist = checklistBox.get(c.dbId);
        if (fullChecklist != null) {
          cleanedIntransitChecklist.add(fullChecklist);
          debugPrint(
            '📋 In-transit Checklist loaded → ${fullChecklist.objectName}',
          );
        }
      }
      trip.checklist.clear();
      trip.checklist.addAll(cleanedIntransitChecklist);

      debugPrint('✅ Trip fully loaded with required relations');
      return trip;
    } catch (e) {
      debugPrint('LOCAL ❌ loadLocalUserTrip ERROR: $e');
      throw CacheException(message: e.toString());
    }
  }
}
