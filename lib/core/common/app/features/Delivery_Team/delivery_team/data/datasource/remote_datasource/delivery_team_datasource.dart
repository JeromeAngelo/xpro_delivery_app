
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class DeliveryTeamDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}

class DeliveryTeamDatasourceImpl implements DeliveryTeamDatasource {
  const DeliveryTeamDatasourceImpl({
    required PocketBase pocketBaseClient,
    required Box<DeliveryTeamModel> deliveryTeamBox,
  })  : _pocketBaseClient = pocketBaseClient,
        _deliveryTeamBox = deliveryTeamBox;

  final PocketBase _pocketBaseClient;
  final Box<DeliveryTeamModel> _deliveryTeamBox;
  

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

    final result = await _pocketBaseClient.collection('delivery_team').getFullList(
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
    
    _deliveryTeamBox.put(deliveryTeamModel);
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

    final record = await _pocketBaseClient.collection('delivery_team').getOne(
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

    _deliveryTeamBox.put(deliveryTeamModel);
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
          'delivery_team': deliveryTeamId,
          'isAccepted': true,
          'timeAccepted': DateTime.now().toIso8601String(),
        },
      );

      // Get updated delivery team data
      final record = await _pocketBaseClient.collection('delivery_team').getOne(
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

}
