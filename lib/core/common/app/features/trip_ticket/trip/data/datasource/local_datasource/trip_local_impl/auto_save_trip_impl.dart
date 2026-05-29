import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin AutoSaveTripImpl on TripLocalBase {
  Future<void> autoSaveTrip(TripModel trip) async {
    try {
      debugPrint('🔄 Auto-saving trip data: ${trip.tripNumberId}');

      // Clear existing trips
      tripBox.removeAll();

      final tripId = trip.id;

      // -------------------------------------------------------------
      // SAVE DELIVERY TEAM
      // -------------------------------------------------------------
      if (trip.deliveryTeam.target != null) {
        final deliveryTeam = trip.deliveryTeam.target!;
        deliveryTeam.tripId = tripId;
        deliveryTeamBox.put(deliveryTeam);
        debugPrint('✅ Saved delivery team: ${deliveryTeam.id}');
      }

      // -------------------------------------------------------------
      // SAVE DELIVERY DATA + CUSTOMER + INVOICE
      // -------------------------------------------------------------
      if (trip.deliveryData.isNotEmpty) {
        for (final delivery in trip.deliveryData) {
          delivery.tripId = tripId;

          if (delivery.customer.target != null) {
            customerBox.put(delivery.customer.target!);
          }

          if (delivery.invoice.target != null) {
            invoiceBox.put(delivery.invoice.target!);
          }

          deliveryDataBox.put(delivery);
        }

        debugPrint('✅ Saved ${trip.deliveryData.length} delivery data records');
      }

      // -------------------------------------------------------------
      // SAVE OTP
      // -------------------------------------------------------------
      if (trip.otp.target != null) {
        final otp = trip.otp.target!;
        otp.tripId = tripId;
        otpBox.put(otp);
        debugPrint('✅ Saved OTP: ${otp.id}');
      }

      // -------------------------------------------------------------
      // SAVE END TRIP OTP
      // -------------------------------------------------------------
      if (trip.endTripOtp.target != null) {
        final endTripOtp = trip.endTripOtp.target!;
        endTripOtp.tripId = tripId;
        endTripOtpBox.put(endTripOtp);
        debugPrint('✅ Saved End Trip OTP: ${endTripOtp.id}');
      }

      // -------------------------------------------------------------
      // SAVE PERSONNEL
      // -------------------------------------------------------------
      if (trip.personels.isNotEmpty) {
        for (final personnel in trip.personels) {
          personnel.tripId = tripId;
          personnelBox.put(personnel);
        }

        debugPrint('✅ Saved ${trip.personels.length} personnel');
      }

      // -------------------------------------------------------------
      // SAVE CHECKLIST ITEMS
      // -------------------------------------------------------------
      if (trip.checklist.isNotEmpty) {
        for (final item in trip.checklist) {
          //item.trip = tripId;
          checklistBox.put(item);
        }

        debugPrint('✅ Saved ${trip.checklist.length} checklist items');
      }

      // -------------------------------------------------------------
      // SAVE THE TRIP ITSELF
      // -------------------------------------------------------------
      final tripToSave = TripModel(
        id: trip.id,
        collectionId: trip.collectionId,
        collectionName: trip.collectionName,
        tripNumberId: trip.tripNumberId,
        totalTripDistance: trip.totalTripDistance,
        qrCode: trip.qrCode,
        created: trip.created,
        updated: trip.updated,
        isAccepted: true,
        timeAccepted: trip.timeAccepted ?? DateTime.now(),
        isEndTrip: trip.isEndTrip,
        timeEndTrip: trip.timeEndTrip,
        objectBoxId: 1,
      );

      final savedTripId = tripBox.put(tripToSave);

      debugPrint('✅ Trip saved with ID: $savedTripId');

      cachedTrip = tripToSave;

      // -------------------------------------------------------------
      // VERIFY SAVE
      // -------------------------------------------------------------
      final savedTrip = tripBox.get(savedTripId);

      if (savedTrip != null) {
        debugPrint('✅ Trip verification successful');
        debugPrint('   🎫 Trip Number: ${savedTrip.tripNumberId}');
        debugPrint('   🔢 Trip ID: ${savedTrip.id}');
        debugPrint('   ✓ Is Accepted: ${savedTrip.isAccepted}');
      } else {
        debugPrint('❌ Trip verification failed — not found after save');
      }

      // -------------------------------------------------------------
      // UPDATE SHARED PREFERENCES
      // -------------------------------------------------------------
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData != null) {
        try {
          final userData = jsonDecode(storedUserData);

          userData['tripNumberId'] = trip.tripNumberId;
          userData['trip'] = {'id': trip.id, 'tripNumberId': trip.tripNumberId};

          await prefs.setString('user_data', jsonEncode(userData));
          debugPrint('✅ Updated user data in SharedPreferences with trip info');
        } catch (e) {
          debugPrint('❌ Failed to update SharedPreferences: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
      throw CacheException(message: e.toString());
    }
  }
}
