import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class DeliveryVehicleRemoteDataSource {
  /// Loads a specific delivery vehicle by its ID
  Future<DeliveryVehicleModel> loadDeliveryVehicleById(String id);
  
  /// Loads all delivery vehicles associated with a specific trip
  Future<List<DeliveryVehicleModel>> loadDeliveryVehiclesByTripId(String tripId);
  
  /// Loads all delivery vehicles in the system
  Future<List<DeliveryVehicleModel>> loadAllDeliveryVehicles();
}

class DeliveryVehicleRemoteDataSourceImpl implements DeliveryVehicleRemoteDataSource {
  final PocketBase _pocketBaseClient;
  
  const DeliveryVehicleRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;
  
  @override
  Future<DeliveryVehicleModel> loadDeliveryVehicleById(String id) async {
    try {
      debugPrint('🔄 Loading delivery vehicle with ID: $id');
      
      final record = await _pocketBaseClient
          .collection('deliveryVehicleData')
          .getOne(id);
      
      final vehicle = DeliveryVehicleModel.fromJson({
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'name': record.data['name'],
        'plate_no': record.data['plate_no'],
        'make': record.data['make'],
        'type': record.data['type'],
        'wheels': record.data['wheels'],
        'volumeCapacity': record.data['volumeCapacity'],
        'weightCapacity': record.data['weightCapacity'],
        'created': record.created,
        'updated': record.updated,
      });
      
      debugPrint('✅ Successfully loaded delivery vehicle: ${vehicle.name}');
      return vehicle;
    } catch (e) {
      debugPrint('❌ Error loading delivery vehicle: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery vehicle: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  
  @override
  Future<List<DeliveryVehicleModel>> loadDeliveryVehiclesByTripId(String tripId) async {
    try {
      debugPrint('🔄 Loading delivery vehicles for trip ID: $tripId');
      
      final records = await _pocketBaseClient
          .collection('deliveryVehicleData')
          .getFullList(
            filter: 'trip = "$tripId"',
          );
      
      final vehicles = records.map((record) => DeliveryVehicleModel.fromJson({
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'name': record.data['name'],
        'plate_no': record.data['plate_no'],
        'make': record.data['make'],
        'type': record.data['type'],
        'wheels': record.data['wheels'],
        'volumeCapacity': record.data['volumeCapacity'],
        'weightCapacity': record.data['weightCapacity'],
        'created': record.created,
        'updated': record.updated,
      })).toList();
      
      debugPrint('✅ Successfully loaded ${vehicles.length} delivery vehicles for trip');
      return vehicles;
    } catch (e) {
      debugPrint('❌ Error loading delivery vehicles by trip: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load delivery vehicles for trip: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
  
  @override
  Future<List<DeliveryVehicleModel>> loadAllDeliveryVehicles() async {
    try {
      debugPrint('🔄 Loading all delivery vehicles');
      
      final records = await _pocketBaseClient
          .collection('deliveryVehicleData')
          .getFullList();
      
      final vehicles = records.map((record) => DeliveryVehicleModel.fromJson({
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'name': record.data['name'],
        'plate_no': record.data['plate_no'],
        'make': record.data['make'],
        'type': record.data['type'],
        'wheels': record.data['wheels'],
        'volumeCapacity': record.data['volumeCapacity'],
        'weightCapacity': record.data['weightCapacity'],
        'created': record.created,
        'updated': record.updated,
      })).toList();
      
      debugPrint('✅ Successfully loaded ${vehicles.length} delivery vehicles');
      return vehicles;
    } catch (e) {
      debugPrint('❌ Error loading all delivery vehicles: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load all delivery vehicles: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
