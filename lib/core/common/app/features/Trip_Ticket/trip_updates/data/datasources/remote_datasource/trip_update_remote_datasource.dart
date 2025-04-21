import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class TripUpdateRemoteDatasource {
  Future<List<TripUpdateModel>> getTripUpdates(String tripId);
  Future<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
}

class TripUpdateRemoteDatasourceImpl implements TripUpdateRemoteDatasource {
  const TripUpdateRemoteDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
Future<List<TripUpdateModel>> getTripUpdates(String tripId) async {
  try {
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');

    final records = await _pocketBaseClient.collection('trip_updates').getFullList(
      filter: 'trip = "$actualTripId"',
      expand: 'trip',
    );

    debugPrint('✅ Retrieved ${records.length} trip updates from API');

    final updates = records.map((record) {
      debugPrint('🔄 Processing trip update: ${record.id}');
      
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'description': record.data['description'] ?? '',
        'status': record.data['status'] ?? '',
        'latitude': record.data['latitude'] ?? '',
        'longitude': record.data['longitude'] ?? '',
        'date': record.data['date'],
        'trip': actualTripId,
        'expand': {
          'trip': record.expand['trip']?.map((trip) => trip.data).first,
        }
      };
      return TripUpdateModel.fromJson(mappedData);
    }).toList();

    debugPrint('✨ Successfully mapped ${updates.length} trip updates');
    return updates;

  } catch (e) {
    debugPrint('❌ Trip updates fetch failed: ${e.toString()}');
    throw ServerException(
      message: 'Failed to load trip updates: ${e.toString()}',
      statusCode: '500',
    );
  }
}

@override
Future<void> createTripUpdate({
  required String tripId,
  required String description,
  required String image,
  required String latitude,
  required String longitude,
  required TripUpdateStatus status,
}) async {
  try {
    // Extract trip ID if we received a JSON object
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }
    
    debugPrint('🎯 Using trip ID: $actualTripId');
    debugPrint('🔄 Creating trip update with status: ${status.toString().split('.').last}');

    final files = <String, MultipartFile>{};

    if (image.isNotEmpty) {
      final imageBytes = await File(image).readAsBytes();
      files['image'] = MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'trip_update_image.jpg',
      );
    }

    final tripUpdateRecord = await _pocketBaseClient.collection('trip_updates').create(
      body: {
        'trip': actualTripId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'date': DateTime.now().toIso8601String(),
        'status': status.toString().split('.').last,
      },
      files: files.values.toList(),
    );

    debugPrint('✅ Created trip update: ${tripUpdateRecord.id}');

    await _pocketBaseClient.collection('tripticket').update(
      actualTripId,
      body: {
        'trip_update_list+': [tripUpdateRecord.id],
      },
    );

    debugPrint('✅ Updated trip with new update record');
  } catch (e) {
    debugPrint('❌ Failed to create trip update: $e');
    throw ServerException(
      message: 'Failed to create trip update: $e',
      statusCode: '500',
    );
  }
}

  
}
