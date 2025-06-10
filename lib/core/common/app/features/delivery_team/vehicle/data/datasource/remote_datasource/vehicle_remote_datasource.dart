import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
abstract class VehicleRemoteDatasource {
  Future<VehicleModel> getVehicles();
  Future<VehicleModel> loadVehicleByDeliveryTeam(String deliveryTeamId);
  Future<VehicleModel> loadVehicleByTripId(String tripId);
}

class VehicleRemoteDatasourceImpl extends VehicleRemoteDatasource {
  VehicleRemoteDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<VehicleModel> getVehicles() async {
    try {
      final result = await _pocketBaseClient.collection('vehicle').getList(
            page: 1,
            perPage: 50,
          );

      return VehicleModel.fromJson(result.toJson());
    } catch (e) {
      throw ServerException(
        message: e.toString(),
        statusCode: '500',
      );
    }
  }

  @override
  Future<VehicleModel> loadVehicleByDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('🌐 Fetching vehicle for delivery team: $deliveryTeamId');
      
      final record = await _pocketBaseClient.collection('vehicle').getFirstListItem(
        'deliveryTeam = "$deliveryTeamId"',
        expand: 'trip,deliveryTeam',
      );

      debugPrint('✅ Vehicle found for delivery team');
      return VehicleModel.fromJson(record.toJson());
    } catch (e) {
      debugPrint('❌ Error fetching vehicle by delivery team: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<VehicleModel> loadVehicleByTripId(String tripId) async {
    try {
      debugPrint('🌐 Fetching vehicle for trip: $tripId');
      
      final record = await _pocketBaseClient.collection('vehicle').getFirstListItem(
        'trip = "$tripId"',
        expand: 'trip,deliveryTeam',
      );

      debugPrint('✅ Vehicle found for trip');
      return VehicleModel.fromJson(record.toJson());
    } catch (e) {
      debugPrint('❌ Error fetching vehicle by trip: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
