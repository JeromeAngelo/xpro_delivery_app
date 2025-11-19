import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/data/model/vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

abstract class VehicleRemoteDatasource {
 Future<List<VehicleModel>> getVehicles();  
 Future<VehicleModel> loadVehicleByDeliveryTeam(String deliveryTeamId);
  Future<VehicleModel> loadVehicleByTripId(String tripId);

  // New CRUD functions
  Future<VehicleModel> createVehicle({
    required String vehicleName,
    required String vehiclePlateNumber,
    required String vehicleType,
    String? deliveryTeamId,
    String? tripId,
  });
  
  Future<VehicleModel> updateVehicle({
    required String vehicleId,
    String? vehicleName,
    String? vehiclePlateNumber,
    String? vehicleType,
    String? deliveryTeamId,
    String? tripId,
  });
  
  Future<bool> deleteVehicle(String vehicleId);
  
  Future<bool> deleteAllVehicles(List<String> vehicleIds);
}

class VehicleRemoteDatasourceImpl extends VehicleRemoteDatasource {
  VehicleRemoteDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      debugPrint('🔄 Fetching all vehicles');
      
      final records = await _pocketBaseClient.collection('vehicle').getFullList(
        expand: 'trip,deliveryTeam',
      );
      
      debugPrint('✅ Successfully fetched ${records.length} vehicles');
      return records.map((record) => VehicleModel.fromJson(record.toJson())).toList();
    } catch (e) {
      debugPrint('❌ Error fetching vehicles: $e');
      throw ServerException(
        message: 'Failed to fetch vehicles: ${e.toString()}',
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
  

  @override
  Future<VehicleModel> createVehicle({
    required String vehicleName,
    required String vehiclePlateNumber,
    required String vehicleType,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Creating new vehicle: $vehicleName, Plate: $vehiclePlateNumber');
      
      // Prepare the request body
      final body = {
        'vehicleName': vehicleName,
        'vehiclePlateNumber': vehiclePlateNumber,
        'vehicleType': vehicleType,
      };
      
      // Add optional fields if provided
      if (deliveryTeamId != null) {
        body['deliveryTeam'] = deliveryTeamId;
      }
      
      if (tripId != null) {
        body['trip'] = tripId;
      }
      
      // Create the record
      final record = await _pocketBaseClient.collection('vehicle').create(
        body: body,
      );
      
      // Get the created record with expanded relations
      final createdRecord = await _pocketBaseClient.collection('vehicle').getOne(
        record.id,
        expand: 'trip,deliveryTeam',
      );
      
      debugPrint('✅ Successfully created vehicle with ID: ${record.id}');
      return VehicleModel.fromJson(createdRecord.toJson());
    } catch (e) {
      debugPrint('❌ Error creating vehicle: $e');
      throw ServerException(
        message: 'Failed to create vehicle: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  @override
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      debugPrint('🔄 Deleting vehicle: $vehicleId');
      
      await _pocketBaseClient.collection('vehicle').delete(vehicleId);
      
      debugPrint('✅ Successfully deleted vehicle');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting vehicle: $e');
      throw ServerException(
        message: 'Failed to delete vehicle: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  
  @override
  Future<bool> deleteAllVehicles(List<String> vehicleIds) async {
    try {
      debugPrint('🔄 Deleting multiple vehicles: ${vehicleIds.length} items');
      
      // Use Future.wait to delete all vehicles in parallel
      await Future.wait(
        vehicleIds.map((id) => _pocketBaseClient.collection('vehicle').delete(id))
      );
      
      debugPrint('✅ Successfully deleted all vehicles');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting multiple vehicles: $e');
      throw ServerException(
        message: 'Failed to delete multiple vehicles: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  

  @override
  Future<VehicleModel> updateVehicle({
    required String vehicleId,
    String? vehicleName,
    String? vehiclePlateNumber,
    String? vehicleType,
    String? deliveryTeamId,
    String? tripId,
  }) async {
    try {
      debugPrint('🔄 Updating vehicle: $vehicleId');
      
      // Prepare the request body with only the fields that need to be updated
      final body = <String, dynamic>{};
      
      if (vehicleName != null) {
        body['vehicleName'] = vehicleName;
      }
      
      if (vehiclePlateNumber != null) {
        body['vehiclePlateNumber'] = vehiclePlateNumber;
      }
      
      if (vehicleType != null) {
        body['vehicleType'] = vehicleType;
      }
      
      // For deliveryTeam and trip, we need to handle both setting and removing
      // If the value is an empty string, it will remove the relation
      if (deliveryTeamId != null) {
        body['deliveryTeam'] = deliveryTeamId.isEmpty ? null : deliveryTeamId;
      }
      
      if (tripId != null) {
        body['trip'] = tripId.isEmpty ? null : tripId;
      }
      
      // Update the record
      await _pocketBaseClient.collection('vehicle').update(
        vehicleId,
        body: body,
      );
      
      // Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient.collection('vehicle').getOne(
        vehicleId,
        expand: 'trip,deliveryTeam',
      );
      
      debugPrint('✅ Successfully updated vehicle');
      return VehicleModel.fromJson(updatedRecord.toJson());
    } catch (e) {
      debugPrint('❌ Error updating vehicle: $e');
      throw ServerException(
        message: 'Failed to update vehicle: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
