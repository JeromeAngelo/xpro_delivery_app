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

      // Use the enhanced DateTime formatting
      final formattedDate = _formatDateTimeForPocketBase(DateTime.now());

      final tripUpdateRecord = await _pocketBaseClient.collection('trip_updates').create(
        body: {
          'trip': actualTripId,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'date': formattedDate, // Use formatted date
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

  // Enhanced getTripUpdates with proper DateTime parsing
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
        
        // Parse the date with enhanced DateTime handling
        final parsedDate = _parseDateTimeFromResponse(record.data['date']);
        
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'description': record.data['description'] ?? '',
          'status': record.data['status'] ?? '',
          'latitude': record.data['latitude'] ?? '',
          'longitude': record.data['longitude'] ?? '',
          'date': parsedDate?.toIso8601String() ?? DateTime.now().toIso8601String(), // Use parsed date
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

  // Enhanced updateTripUpdate with proper DateTime handling
 

String _formatDateTimeForPocketBase(DateTime dateTime) {
    try {
      // PocketBase expects ISO 8601 format with proper timezone
      // Format: YYYY-MM-DDTHH:mm:ss.sssZ
      final formattedDate = dateTime.toUtc().toIso8601String();
      
      debugPrint('📅 Formatted DateTime: $formattedDate');
      return formattedDate;
    } catch (e) {
      debugPrint('❌ Error formatting DateTime: $e');
      // Fallback to current time if formatting fails
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  // Helper function to parse DateTime from various formats
  DateTime? _parseDateTimeFromResponse(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is String) {
        // Handle various date formats that might come from PocketBase
        if (dateValue.isEmpty) return null;
        
        // Try ISO 8601 format first
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          debugPrint('⚠️ Failed to parse ISO format: $dateValue');
        }
        
        // Try with timezone suffix variations
        final cleanedDate = dateValue
            .replaceAll('Z', '')
            .replaceAll('+00:00', '')
            .replaceAll('T', ' ');
            
        try {
          return DateTime.parse(cleanedDate);
        } catch (e) {
          debugPrint('⚠️ Failed to parse cleaned format: $cleanedDate');
        }
        
        // Try manual parsing for custom formats
        final dateRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})\s*(\d{2}):(\d{2}):(\d{2})');
        final match = dateRegex.firstMatch(dateValue);
        
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
          );
        }
      } else if (dateValue is DateTime) {
        return dateValue;
      } else if (dateValue is int) {
        // Handle timestamp (milliseconds since epoch)
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      
      debugPrint('⚠️ Unsupported date format: $dateValue (${dateValue.runtimeType})');
      return null;
    } catch (e) {
      debugPrint('❌ Error parsing DateTime: $e');
      return null;
    }
  }

  
}
