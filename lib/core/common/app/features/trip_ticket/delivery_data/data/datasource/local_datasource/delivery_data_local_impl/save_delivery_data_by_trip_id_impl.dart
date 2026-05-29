import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin SaveDeliveryDataByTripIdImpl on DeliveryDataLocalBase {
  Future<void> saveDeliveryDataByTripId(
    String tripId,
    List<DeliveryDataModel> deliveryData,
  ) async {
    try {
      debugPrint('💾 LOCAL: Saving delivery data for tripId: $tripId');
      debugPrint('📥 LOCAL: Received ${deliveryData.length} delivery items');

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first (OFFLINE-FIRST, RELATION-BASED)
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found in local DB for tripId: $tripId');
        throw CacheException(message: 'Trip not found in local DB');
      }

      debugPrint('🚛 Trip found → ${trip.name} (OBX: ${trip.objectBoxId})');

      // -------------------------------------------------------------
      // 2️⃣ Cleanup existing delivery data linked to this trip
      // -------------------------------------------------------------
      await cleanupDeliveryDataByTrip(trip);
      debugPrint('🧹 LOCAL: Existing delivery data cleared for trip');

      // -------------------------------------------------------------
      // 3️⃣ Prepare & attach delivery data to trip
      // -------------------------------------------------------------
      final preparedData = <DeliveryDataModel>[];

      for (final data in deliveryData) {
        debugPrint('🔍 Preparing DeliveryData → ${data.id}');

        // Attach trip relation (CRITICAL)
        data.trip.target = trip;
        data.tripId = trip.id;

        preparedData.add(data);
      }

      // -------------------------------------------------------------
      // 4️⃣ Save DeliveryData to ObjectBox
      // -------------------------------------------------------------
      final storedIds = deliveryDataBox.putMany(preparedData);

      debugPrint(
        '💾 LOCAL: Saved ${storedIds.length} delivery data records to ObjectBox',
      );

      // -------------------------------------------------------------
      // 5️⃣ Attach saved DeliveryData back to Trip
      // -------------------------------------------------------------
      final savedDeliveryData =
          storedIds.map((id) => deliveryDataBox.get(id)!).toList();

      trip.deliveryData
        ..clear()
        ..addAll(savedDeliveryData);

      tripBox.put(trip);

      debugPrint(
        '🔗 LOCAL: Trip updated → ${trip.name} now has ${trip.deliveryData.length} delivery items',
      );

      // -------------------------------------------------------------
      // 6️⃣ Update in-memory cache
      // -------------------------------------------------------------
      cachedDeliveryData = deliveryDataBox.getAll();
      debugPrint('🔄 LOCAL: In-memory cache updated');
    } catch (e, st) {
      debugPrint('❌ LOCAL: saveDeliveryDataByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
