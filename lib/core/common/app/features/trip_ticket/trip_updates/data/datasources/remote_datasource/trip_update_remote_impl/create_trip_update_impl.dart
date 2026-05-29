import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/datasources/remote_datasource/trip_update_remote_impl/trip_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CreateTripUpdateImpl on TripUpdateRemoteBase {
  Future<String> createTripUpdate({
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
      debugPrint(
        '🔄 Creating trip update with status: ${status.toString().split('.').last}',
      );

      final files = <MultipartFile>[];

      if (image.isNotEmpty) {
        try {
          final imageFile = File(image);
          if (await imageFile.exists()) {
            debugPrint('📸 Processing trip update image...');

            // Compress the image using the same method as delivery receipt
            final compressedImageBytes = await compressImage(image);
            if (compressedImageBytes != null) {
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  compressedImageBytes,
                  filename:
                      'trip_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '✅ Added compressed trip update image (${compressedImageBytes.length} bytes)',
              );
            } else {
              // Fallback to original if compression fails
              final originalBytes = await imageFile.readAsBytes();
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  originalBytes,
                  filename:
                      'trip_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '⚠️ Using original image (compression failed): ${originalBytes.length} bytes',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing trip update image: $e');
        }
      }

      // Use the enhanced DateTime formatting
      final formattedDate = formatDateTimeForPocketBase(DateTime.now());

      // Calculate total file size
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
      debugPrint(
        '📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      debugPrint('📦 Creating trip update with ${files.length} files');
      debugPrint('⏱️ Starting optimized remote creation...');

      final startTime = DateTime.now();

      final tripUpdateRecord = await pocketBaseClient
          .collection('tripUpdates')
          .create(
            body: {
              'trip': actualTripId,
              'description': description,
              'latitude': latitude,
              'longitude': longitude,
              'date': formattedDate, // Use formatted date
              'status': status.toString().split('.').last,
            },
            files: files,
          );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

      debugPrint('✅ Created trip update: ${tripUpdateRecord.id}');

      await pocketBaseClient
          .collection('tripticket')
          .update(
            actualTripId,
            body: {
              'trip_update_list+': [tripUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated trip with new update record');

      await pocketBaseClient
          .collection('notifications')
          .create(
            body: {
              'tripUpdate': tripUpdateRecord.id,
              'trip': actualTripId,
              'type': 'tripUpdate',
              'created': formattedDate,
            },
          );
      debugPrint('✅ Created notification for trip update');

      // ✅ REQUIRED RETURN
      return tripUpdateRecord.id;
    } catch (e) {
      debugPrint('❌ Failed to create trip update: $e');
      throw ServerException(
        message: 'Failed to create trip update: $e',
        statusCode: '500',
      );
    }
  }
}
