
import 'dart:convert';


import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../personels/data/models/personel_models.dart';
import '../../../../../vehicle/delivery_vehicle_data/data/model/vehicle_model.dart';
import '../../models/delivery_team_model.dart';


abstract class DeliveryTeamDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });

  // New functions
  Future<DeliveryTeamModel> createDeliveryTeam({
    required String deliveryTeamId,
    required VehicleModel vehicle,
    required List<PersonelModel> personels,
    required TripModel tripId,
  });
  
  Future<DeliveryTeamModel> updateDeliveryTeam({
    required String deliveryTeamId,
    required VehicleModel vehicle,
    required List<PersonelModel> personels,
    required TripModel tripId,
  });
  
  Future<bool> deleteDeliveryTeam(String deliveryTeamId);
  
  Future<List<DeliveryTeamModel>> loadAllDeliveryTeam();
}

class DeliveryTeamDatasourceImpl implements DeliveryTeamDatasource {
  const DeliveryTeamDatasourceImpl({
    required PocketBase pocketBaseClient,
  
  })  : _pocketBaseClient = pocketBaseClient;
       

  final PocketBase _pocketBaseClient;
  
  

@override
Future<DeliveryTeamModel> loadDeliveryTeam(String tripId) async {
  try {
    debugPrint('🔄 Starting delivery team load');
    
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');

    final result = await _pocketBaseClient.collection('deliveryTeam').getFullList(
      expand: 'personels,vehicle,tripTicket',
      filter: 'tripTicket = "$actualTripId"',
    );

    if (result.isEmpty) {
      throw const ServerException(
        message: 'No delivery team found for this trip',
        statusCode: '404',
      );
    }

    final record = result.first;
    final mappedData = _mapDeliveryTeamData(record);
    final deliveryTeamModel = DeliveryTeamModel.fromJson(mappedData);
    
    debugPrint('✅ Delivery team data cached successfully');
    
    return deliveryTeamModel;
  } catch (e) {
    debugPrint('❌ Error in delivery team load: $e');
    throw ServerException(
      message: 'Failed to load delivery team: ${e.toString()}',
      statusCode: '500',
    );
  }
}


@override
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId) async {
  try {
    debugPrint('📍 Fetching data for delivery team: $deliveryTeamId');

    final record = await _pocketBaseClient.collection('deliveryTeam').getOne(
      deliveryTeamId,
      expand: 'personels,vehicle,tripTicket',
    );

    final personelsList = (record.expand['personels'] as List?)?.map((personnel) {
      final personnelRecord = personnel as RecordModel;
      debugPrint('🧑‍💼 Processing team member: ${personnelRecord.id}');
      
      return PersonelModel.fromJson({
        'id': personnelRecord.id,
        'collectionId': personnelRecord.collectionId,
        'collectionName': personnelRecord.collectionName,
        'name': personnelRecord.data['name'] ?? 'Unnamed',
        'role': personnelRecord.data['role'],
        'created': personnelRecord.created,
        'updated': personnelRecord.updated
      });
    }).toList() ?? [];

    final vehicleList = (record.expand['vehicle'] as List?)?.map((vehicle) {
      final vehicleRecord = vehicle as RecordModel;
      debugPrint('🚛 Processing vehicle: ${vehicleRecord.id}');
      
      return VehicleModel.fromJson({
        'id': vehicleRecord.id,
        'collectionId': vehicleRecord.collectionId,
        'collectionName': vehicleRecord.collectionName,
        'plateNumber': vehicleRecord.data['plateNumber'],
        'type': vehicleRecord.data['type'],
        'created': vehicleRecord.created,
        'updated': vehicleRecord.updated
      });
    }).toList() ?? [];

    final deliveryTeamModel = DeliveryTeamModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      personels: personelsList,
      vehicleList: vehicleList,
      activeDeliveries: record.data['activeDeliveries'],
      totalDelivered: record.data['totalDelivered'],
      undeliveredCustomers: record.data['undeliveredCustomers'],
      totalDistanceTravelled: record.data['totalDistanceTravelled'],
    );

    debugPrint('✅ Delivery team data saved to local storage');

    return deliveryTeamModel;
  } catch (e) {
    debugPrint('❌ Error fetching delivery team by ID: $e');
    throw ServerException(
      message: 'Failed to load delivery team by ID: ${e.toString()}',
      statusCode: '500',
    );
  }
}


  @override
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  }) async {
    try {
      debugPrint(
          '🔄 Assigning delivery team: $deliveryTeamId to trip: $tripId');

      // Update trip with delivery team
      await _pocketBaseClient.collection('tripticket').update(
        tripId,
        body: {
          'deliveryTeam': deliveryTeamId,
          'isAccepted': true,
          'timeAccepted': DateTime.now().toIso8601String(),
        },
      );

      // Get updated delivery team data
      final record = await _pocketBaseClient.collection('deliveryTeam').getOne(
            deliveryTeamId,
            expand: 'personels,vehicle,tripTicket',
          );

      debugPrint('✅ Successfully assigned delivery team to trip');
      return DeliveryTeamModel.fromJson(record.toJson());
    } catch (e) {
      debugPrint('❌ Error assigning delivery team: ${e.toString()}');
      throw ServerException(
        message: 'Failed to assign delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  Map<String, dynamic> _mapDeliveryTeamData(RecordModel record) {
  return {
    'id': record.id,
    'collectionId': record.collectionId,
    'collectionName': record.collectionName,
    'activeDeliveries': record.data['activeDeliveries'],
    'totalDelivered': record.data['totalDelivered'],
    'undeliveredCustomers': record.data['undeliveredCustomers'],
    'totalDistanceTravelled': record.data['totalDistanceTravelled'],
    'expand': {
      'personels': _mapExpandedList(record.expand['personels']),
      'vehicle': _mapExpandedList(record.expand['vehicle']),
      'tripTicket': record.data['tripTicket'],
    }
  };
}


List<Map<String, dynamic>> _mapExpandedList(dynamic records) {
  if (records == null) return [];
  
  if (records is List) {
    return records.map((record) {
      if (record is RecordModel) {
        return <String, dynamic>{
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          ...Map<String, dynamic>.from(record.data),
        };
      }
      return <String, dynamic>{};
    }).toList();
  }
  
  if (records is RecordModel) {
    return [<String, dynamic>{
      'id': records.id,
      'collectionId': records.collectionId,
      'collectionName': records.collectionName,
      ...Map<String, dynamic>.from(records.data),
    }];
  }
  
  return [];
}

 @override
  Future<DeliveryTeamModel> createDeliveryTeam({
    required String deliveryTeamId,
    required VehicleModel vehicle,
    required List<PersonelModel> personels,
    required TripEntity tripId,
  }) async {
    try {
      debugPrint('🔄 Creating new delivery team');
      
      // Prepare personnel IDs
      final personelIds = personels.map((p) => p.id).toList();
      
      // Create delivery team record
      final record = await _pocketBaseClient.collection('deliveryTeam').create(
        body: {
          'id': deliveryTeamId,
          'vehicle': vehicle.id,
          'personels': personelIds,
          'tripTicket': tripId.id,
          'activeDeliveries': '0',
          'totalDelivered': '0',
          'undeliveredCustomers': '0',
          'totalDistanceTravelled': '0',
        },
      );
      
      // Get the created record with expanded relations
      final createdRecord = await _pocketBaseClient.collection('deliveryTeam').getOne(
        record.id,
        expand: 'personels,vehicle,tripTicket',
      );
      
      debugPrint('✅ Successfully created delivery team: ${record.id}');
      
      final mappedData = _mapDeliveryTeamData(createdRecord);
      return DeliveryTeamModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error creating delivery team: $e');
      throw ServerException(
        message: 'Failed to create delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteDeliveryTeam(String deliveryTeamId) async {
    try {
      debugPrint('🔄 Deleting delivery team: $deliveryTeamId');
      
      await _pocketBaseClient.collection('deliveryTeam').delete(deliveryTeamId);
      
      debugPrint('✅ Successfully deleted delivery team');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting delivery team: $e');
      throw ServerException(
        message: 'Failed to delete delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }


  @override
  Future<List<DeliveryTeamModel>> loadAllDeliveryTeam() async {
    try {
      debugPrint('🔄 Loading all delivery teams');
      
      final records = await _pocketBaseClient.collection('deliveryTeam').getFullList(
        expand: 'personels,vehicle,tripTicket',
      );
      
      if (records.isEmpty) {
        debugPrint('⚠️ No delivery teams found');
        return [];
      }
      
      final teams = records.map((record) {
        final mappedData = _mapDeliveryTeamData(record);
        return DeliveryTeamModel.fromJson(mappedData);
      }).toList();
      
      debugPrint('✅ Loaded ${teams.length} delivery teams');
      return teams;
    } catch (e) {
      debugPrint('❌ Error loading all delivery teams: $e');
      throw ServerException(
        message: 'Failed to load all delivery teams: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

 
  @override
  Future<DeliveryTeamModel> updateDeliveryTeam({
    required String deliveryTeamId,
    required VehicleModel vehicle,
    required List<PersonelModel> personels,
    required TripEntity tripId,
  }) async {
    try {
      debugPrint('🔄 Updating delivery team: $deliveryTeamId');
      
      // Prepare personnel IDs
      final personelIds = personels.map((p) => p.id).toList();
      
      // Update delivery team record
      await _pocketBaseClient.collection('deliveryTeam').update(
        deliveryTeamId,
        body: {
          'vehicle': vehicle.id,
          'personels': personelIds,
          'tripTicket': tripId.id,
        },
      );
      
      // Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient.collection('deliveryTeam').getOne(
        deliveryTeamId,
        expand: 'personels,vehicle,tripTicket',
      );
      
      debugPrint('✅ Successfully updated delivery team');
      
      final mappedData = _mapDeliveryTeamData(updatedRecord);
      return DeliveryTeamModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error updating delivery team: $e');
      throw ServerException(
        message: 'Failed to update delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

}
