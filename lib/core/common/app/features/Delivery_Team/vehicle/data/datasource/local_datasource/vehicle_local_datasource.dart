import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
abstract class VehicleLocalDatasource {
  Future<VehicleModel> getVehicles();
  Future<VehicleModel> loadVehicleByDeliveryTeam(String deliveryTeamId);
  Future<VehicleModel> loadVehicleByTripId(String tripId);
}

class VehicleLocalDatasourceImpl implements VehicleLocalDatasource {
  final Box<VehicleModel> _vehicleBox;

  VehicleLocalDatasourceImpl(this._vehicleBox);

  @override
  Future<VehicleModel> getVehicles() async {
    try {
      final vehicles = _vehicleBox.getAll();
      if (vehicles.isEmpty) {
        throw const CacheException(message: 'No vehicles found in local storage');
      }
      return vehicles.first;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<VehicleModel> loadVehicleByDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('📱 Loading vehicle for delivery team: $deliveryTeamId');
      final query = _vehicleBox.query(VehicleModel_.deliveryTeamId.equals(deliveryTeamId)).build();
      final vehicle = query.findFirst();
      query.close();

      if (vehicle == null) {
        throw const CacheException(message: 'Vehicle not found for delivery team');
      }

      debugPrint('✅ Found vehicle in local storage');
      return vehicle;
    } catch (e) {
      debugPrint('❌ Error loading vehicle by delivery team: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<VehicleModel> loadVehicleByTripId(String tripId) async {
    try {
      debugPrint('📱 Loading vehicle for trip: $tripId');
      final query = _vehicleBox.query(VehicleModel_.tripId.equals(tripId)).build();
      final vehicle = query.findFirst();
      query.close();

      if (vehicle == null) {
        throw const CacheException(message: 'Vehicle not found for trip');
      }

      debugPrint('✅ Found vehicle in local storage');
      return vehicle;
    } catch (e) {
      debugPrint('❌ Error loading vehicle by trip: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
