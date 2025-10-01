
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../Trip_Ticket/trip/data/models/trip_models.dart';
import '../../../../personels/data/models/personel_models.dart';
import '../../models/delivery_team_model.dart';

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
debugPrint('🔄 Starting delivery team load with trip ID: $tripId');

// Extract trip ID if we received a JSON object
String actualTripId;
if (tripId.startsWith('{')) {
final tripData = jsonDecode(tripId);
actualTripId = tripData['id'];
} else {
actualTripId = tripId;
}

debugPrint('🎯 Extracted trip ID: $actualTripId');

// If actualTripId looks like a tripNumberId (starts with TRIP-), 
// we need to find the actual PocketBase record ID
String pocketBaseTripId = actualTripId;

    if (actualTripId.startsWith('TRIP-')) {
      debugPrint('🔍 Trip ID appears to be tripNumberId, finding PocketBase record ID...');
      try {
        final tripResults = await _pocketBaseClient.collection('tripticket').getFullList(
          filter: 'tripNumberId = "$actualTripId"',
        );
        
        if (tripResults.isNotEmpty) {
          pocketBaseTripId = tripResults.first.id;
          debugPrint('✅ Found PocketBase trip ID: $pocketBaseTripId for tripNumberId: $actualTripId');
        } else {
          debugPrint('⚠️ No trip found with tripNumberId: $actualTripId');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to resolve tripNumberId: $e');
      }
    }

    final result = await _pocketBaseClient.collection('deliveryTeam').getFullList(
      expand: 'personels,tripTicket,deliveryVehicle',
      filter: 'tripTicket = "$pocketBaseTripId"',
    );

    if (result.isEmpty) {
      throw const ServerException(
        message: 'No delivery team found for this trip',
        statusCode: '404',
      );
    }

    final record = result.first;
    
    // FIXED: Process the record like delivery data datasource
    final deliveryTeamModel = _processDeliveryTeamRecord(record);
    
    debugPrint('✅ Delivery team data processed successfully');
    
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
      expand: 'personels,tripTicket,deliveryVehicle, checklist',
    );

    // FIXED: Process the record like delivery data datasource
    final deliveryTeamModel = _processDeliveryTeamRecord(record);

    debugPrint('✅ Delivery team data processed successfully');     

    return deliveryTeamModel;
  } catch (e) {
    debugPrint('❌ Error fetching delivery team by ID: $e');
    throw ServerException(
      message: 'Failed to load delivery team by ID: ${e.toString()}',
      statusCode: '500',
    );
  }
}
// FIXED: Process delivery team record with proper type conversion
DeliveryTeamModel _processDeliveryTeamRecord(RecordModel record) {
  // Process personels data
  List<PersonelModel> personelsList = [];
  if (record.expand['personels'] != null) {
    final personelsData = record.expand['personels'];
    if (personelsData is List) {
      personelsList = personelsData!.map((personnel) {
        final personnelRecord = personnel;
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
      }).toList();
    }
  } else if (record.data['personels'] != null) {
    personelsList = (record.data['personels'] as List)
        .map((id) => PersonelModel(id: id.toString()))
        .toList();
  }

  // // Process vehicle data
  // List<VehicleModel> vehicleList = [];
  // if (record.expand['vehicle'] != null) {
  //   final vehicleData = record.expand['vehicle'];
  //   if (vehicleData is List) {
  //     vehicleList = vehicleData!.map((vehicle) {
  //       final vehicleRecord = vehicle;
  //       debugPrint('🚛 Processing vehicle: ${vehicleRecord.id}');
        
  //       return VehicleModel.fromJson({
  //         'id': vehicleRecord.id,
  //         'collectionId': vehicleRecord.collectionId,
  //         'collectionName': vehicleRecord.collectionName,
  //         'plateNumber': vehicleRecord.data['plateNumber'],
  //         'type': vehicleRecord.data['type'],
  //         'created': vehicleRecord.created,
  //         'updated': vehicleRecord.updated
  //       });
  //     }).toList();
  //   }
  // } else if (record.data['vehicle'] != null) {
  //   vehicleList = (record.data['vehicle'] as List)
  //       .map((id) => VehicleModel(id: id.toString()))
  //       .toList();
  // }

  // FIXED: Process delivery vehicle data with proper null handling
  DeliveryVehicleModel? deliveryVehicleModel;
  if (record.expand['deliveryVehicle'] != null) {
    final deliveryVehicleData = record.expand['deliveryVehicle'];
     if (deliveryVehicleData is List && deliveryVehicleData!.isNotEmpty) {
      final vehicleRecord = deliveryVehicleData[0];
      debugPrint('🚛 Processing delivery vehicle from list: ${vehicleRecord.id}');
      debugPrint('🚛 Vehicle data from list: ${vehicleRecord.data}');
      
      deliveryVehicleModel = DeliveryVehicleModel.fromJson({
        'id': vehicleRecord.id,
        'collectionId': vehicleRecord.collectionId,
        'collectionName': vehicleRecord.collectionName,
        'plate_no': vehicleRecord.data['plate_no']?.toString(),
        'make': vehicleRecord.data['make']?.toString(),
        'name': vehicleRecord.data['name']?.toString(),
        'model': vehicleRecord.data['model']?.toString(),
        'type': vehicleRecord.data['type']?.toString(),
        'wheels': vehicleRecord.data['wheels']?.toString(),
        'volumeCapacity': vehicleRecord.data['volumeCapacity']?.toString(),
        'weightCapacity': vehicleRecord.data['weightCapacity']?.toString(),
        'year': vehicleRecord.data['year']?.toString(),
        'capacity': vehicleRecord.data['capacity']?.toString(),
        'fuelType': vehicleRecord.data['fuelType']?.toString(),
        'status': vehicleRecord.data['status']?.toString(),
        'created': vehicleRecord.created,
        'updated': vehicleRecord.updated,
      });
      debugPrint('✅ Delivery vehicle processed from list: ${deliveryVehicleModel.plateNo}');
    }
  } else if (record.data['deliveryVehicle'] != null) {
    debugPrint('⚠️ Delivery vehicle ID found but not expanded: ${record.data['deliveryVehicle']}');
    // Create a minimal model with just the ID
    deliveryVehicleModel = DeliveryVehicleModel(id: record.data['deliveryVehicle'].toString());
  }

  // Process trip data
  TripModel? tripModel;
  if (record.expand['tripTicket'] != null) {
    final tripData = record.expand['tripTicket'];
    if (tripData is List && tripData!.isNotEmpty) {
      final tripRecord = tripData[0];
      debugPrint('🎫 Processing trip from list: ${tripRecord.id}');
      tripModel = TripModel.fromJson({
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        'tripNumberId': tripRecord.data['tripNumberId'],
        'qrCode': tripRecord.data['qrCode'],
        'isAccepted': tripRecord.data['isAccepted'],
        'isEndTrip': tripRecord.data['isEndTrip'],
      });
    }
  } else if (record.data['tripTicket'] != null) {
    tripModel = TripModel(id: record.data['tripTicket'].toString());
  }

  debugPrint('📊 Final processing results:');
  debugPrint('   👥 Personels: ${personelsList.length}');
  debugPrint('   🚛 Delivery Vehicle: ${deliveryVehicleModel?.plateNo ?? "null"}');
  debugPrint('   🎫 Trip: ${tripModel?.tripNumberId ?? "null"}');

  // FIXED: Safe type conversion for numeric fields
  return DeliveryTeamModel(
    id: record.id,
    collectionId: record.collectionId,
    collectionName: record.collectionName,
    personels: personelsList,
    deliveryVehicleModel: deliveryVehicleModel,
    tripModel: tripModel,
    activeDeliveries: _safeParseInt(record.data['activeDeliveries']),
    totalDelivered: _safeParseInt(record.data['totalDelivered']),
    undeliveredCustomers: _safeParseInt(record.data['undeliveredCustomers']),
    totalDistanceTravelled: _safeParseDouble(record.data['totalDistanceTraveled']),
  );
}

// ADDED: Safe parsing methods to handle type conversion
int? _safeParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  if (value is double) return value.toInt();
  return null;
}

double? _safeParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

  @override
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({required String tripId, required String deliveryTeamId}) {
    // TODO: implement assignDeliveryTeamToTrip
    throw UnimplementedError();
  }






}
