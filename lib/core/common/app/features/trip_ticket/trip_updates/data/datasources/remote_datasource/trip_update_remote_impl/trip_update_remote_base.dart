import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart' show PocketBase, RecordModel;
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/data/model/trip_update_model.dart';
import 'dart:typed_data' show Uint8List;
import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract class TripUpdateRemoteBase {
  final PocketBase pocketBaseClient;

  const TripUpdateRemoteBase({required this.pocketBaseClient});

  // ================================================================
  // HELPER METHODS (formerly private, now public for mixin access)
  // ================================================================

  /// Compress image file to reduce size
  Future<Uint8List?> compressImage(String imagePath) async {
    try {
      debugPrint('🗜️ Compressing trip update image: $imagePath');

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 70, // 70% quality
        minWidth: 800, // Max width 800px
        minHeight: 600, // Max height 600px
        format: CompressFormat.jpeg,
      );

      if (compressedBytes != null) {
        final originalSize = await File(imagePath).length();
        debugPrint(
          '📊 Trip update image compressed: $originalSize bytes -> ${compressedBytes.length} bytes',
        );
        debugPrint(
          '📉 Compression ratio: ${((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
        );
      }

      return compressedBytes;
    } catch (e) {
      debugPrint('⚠️ Trip update image compression failed: $e');
      // Fallback to original file
      try {
        return await File(imagePath).readAsBytes();
      } catch (fallbackError) {
        debugPrint('❌ Failed to read original image file: $fallbackError');
        return null;
      }
    }
  }

  /// Process a trip update record similar to delivery data processing
  TripUpdateModel processTripUpdateRecord(RecordModel record, String tripId) {
    try {
      // Process expanded trip data if available
      TripModel? tripModel;
      if (record.expand['trip'] != null) {
        final tripData = record.expand['trip'];
        if (tripData is List && tripData!.isNotEmpty) {
          final tripRecord = tripData[0];
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
      } else if (record.data['trip'] != null) {
        tripModel = TripModel(id: record.data['trip'].toString());
      }

      // Parse dates safely
      DateTime? parsedDate;
      DateTime? createdDate;
      DateTime? updatedDate;

      // Parse the main date field
      if (record.data['date'] != null) {
        parsedDate = parseDateTimeFromResponse(record.data['date']);
      }

      // Parse created date
      if (record.data['created'] != null) {
        createdDate = parseDateTimeFromResponse(record.data['created']);
      }

      // Parse updated date
      if (record.data['updated'] != null) {
        updatedDate = parseDateTimeFromResponse(record.data['updated']);
      }

      // Parse status safely
      TripUpdateStatus? status;
      final statusString = record.data['status'];
      if (statusString != null && statusString is String) {
        try {
          status = parseTripUpdateStatus(statusString);
        } catch (e) {
          debugPrint('⚠️ Failed to parse status "$statusString": $e');
          status = TripUpdateStatus.others; // Default fallback
        }
      }

      // Create the mapped data
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'description': record.data['description'] ?? '',
        'status': status?.name ?? 'others',
        'latitude': record.data['latitude']?.toString() ?? '',
        'longitude': record.data['longitude']?.toString() ?? '',
        'date':
            parsedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'created':
            createdDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated':
            updatedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'trip': tripId,
        'image': record.data['image'] ?? '',
        'expand': {'trip': tripModel?.toJson()},
      };

      debugPrint('✅ Successfully processed trip update: ${record.id}');
      return TripUpdateModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error processing trip update record ${record.id}: $e');

      // Return a minimal valid model as fallback
      return TripUpdateModel.fromJson({
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'description':
            record.data['description'] ?? 'Error loading description',
        'status': parseTripUpdateStatus,
        'latitude': '',
        'longitude': '',
        'date': DateTime.now().toIso8601String(),
        'created': DateTime.now().toIso8601String(),
        'updated': DateTime.now().toIso8601String(),
        'trip': tripId,
        'image': '',
      });
    }
  }

  /// Parse TripUpdateStatus from string
  TripUpdateStatus parseTripUpdateStatus(String statusString) {
    final normalizedStatus = statusString.toLowerCase().trim();
    debugPrint(
      '🎯 TRIP STATUS: Parsing "$statusString" → normalized: "$normalizedStatus"',
    );

    switch (normalizedStatus) {
      case 'generalupdate':
        return TripUpdateStatus.generalUpdate;
      case 'refuelling':
        return TripUpdateStatus.refuelling;
      case 'roadclosure':
        return TripUpdateStatus.roadClosure;
      case 'vehiclebreakdown':
        return TripUpdateStatus.vehicleBreakdown;
      case 'none':
        return TripUpdateStatus.none;

      case 'others':
      default:
        debugPrint(
          '⚠️ TRIP STATUS: Unmatched status "$normalizedStatus", defaulting to others',
        );
        return TripUpdateStatus.others;
    }
  }

  // Enhanced helper function to parse DateTime from various formats (same as delivery data)
  DateTime? parseDateTimeFromResponse(dynamic dateValue) {
    if (dateValue == null) {
      debugPrint('⚠️ Date value is null, using current time');
      return DateTime.now();
    }

    try {
      if (dateValue is String) {
        // Handle various date formats that might come from PocketBase
        if (dateValue.isEmpty) {
          debugPrint('⚠️ Date string is empty, using current time');
          return DateTime.now();
        }

        debugPrint('📅 Parsing date string: $dateValue');

        // Try ISO 8601 format first (most common)
        try {
          final parsed = DateTime.parse(dateValue);
          debugPrint('✅ Successfully parsed ISO date: $parsed');
          return parsed;
        } catch (e) {
          debugPrint('⚠️ Failed to parse as ISO format: $e');
        }

        // Try with timezone suffix variations
        try {
          String cleanedDate = dateValue;

          // Remove various timezone indicators
          cleanedDate =
              cleanedDate
                  .replaceAll('Z', '')
                  .replaceAll('+00:00', '')
                  .replaceAll('UTC', '')
                  .trim();

          // If it has 'T', try parsing as ISO without timezone
          if (cleanedDate.contains('T')) {
            final parsed = DateTime.parse(cleanedDate);
            debugPrint('✅ Successfully parsed cleaned ISO date: $parsed');
            return parsed;
          }

          // Try replacing T with space for alternative format
          cleanedDate = cleanedDate.replaceAll('T', ' ');
          final parsed = DateTime.parse(cleanedDate);
          debugPrint('✅ Successfully parsed space-separated date: $parsed');
          return parsed;
        } catch (e) {
          debugPrint('⚠️ Failed to parse cleaned format: $e');
        }

        // Try manual parsing for custom formats like "YYYY-MM-DD HH:mm:ss"
        try {
          final dateRegex = RegExp(
            r'(\d{4})-(\d{2})-(\d{2})[\s|T](\d{2}):(\d{2}):(\d{2})',
          );
          final match = dateRegex.firstMatch(dateValue);

          if (match != null) {
            final parsed = DateTime(
              int.parse(match.group(1)!), // year
              int.parse(match.group(2)!), // month
              int.parse(match.group(3)!), // day
              int.parse(match.group(4)!), // hour
              int.parse(match.group(5)!), // minute
              int.parse(match.group(6)!), // second
            );
            debugPrint('✅ Successfully parsed with regex: $parsed');
            return parsed;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse with regex: $e');
        }

        // Try parsing just the date part if time parsing fails
        try {
          final dateOnlyRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
          final match = dateOnlyRegex.firstMatch(dateValue);

          if (match != null) {
            final parsed = DateTime(
              int.parse(match.group(1)!), // year
              int.parse(match.group(2)!), // month
              int.parse(match.group(3)!), // day
            );
            debugPrint('✅ Successfully parsed date only: $parsed');
            return parsed;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse date only: $e');
        }
      } else if (dateValue is DateTime) {
        debugPrint('✅ Date value is already DateTime: $dateValue');
        return dateValue;
      } else if (dateValue is int) {
        // Handle timestamp (milliseconds since epoch)
        try {
          final parsed = DateTime.fromMillisecondsSinceEpoch(dateValue);
          debugPrint('✅ Successfully parsed timestamp: $parsed');
          return parsed;
        } catch (e) {
          debugPrint('⚠️ Failed to parse timestamp: $e');
        }
      }

      debugPrint(
        '⚠️ Unsupported date format: $dateValue (${dateValue.runtimeType})',
      );
      return DateTime.now(); // Fallback to current time
    } catch (e) {
      debugPrint('❌ Error parsing DateTime: $e');
      debugPrint('📅 Using current time as fallback');
      return DateTime.now(); // Always return a valid DateTime
    }
  }

  String formatDateTimeForPocketBase(DateTime dateTime) {
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
}
