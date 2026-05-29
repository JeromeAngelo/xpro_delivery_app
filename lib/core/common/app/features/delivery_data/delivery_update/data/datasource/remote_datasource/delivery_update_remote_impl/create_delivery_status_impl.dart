import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CreateDeliveryStatusImpl on DeliveryUpdateRemoteBase {
  Future<void> createDeliveryStatus(
    String customerId, {
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isAssigned,
    required String image,
  }) async {
    try {
      debugPrint('📝 Creating delivery status for customer: $customerId');

      final files = <MultipartFile>[];

      if (image.isNotEmpty) {
        try {
          final imageFile = File(image);
          if (await imageFile.exists()) {
            debugPrint('📸 Processing delivery status image...');

            // Compress the image to very small size
            final compressedImageBytes = await compressImageToSmallSize(image);
            if (compressedImageBytes != null) {
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  compressedImageBytes,
                  filename:
                      'delivery_status_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '✅ Added compressed delivery status image (${compressedImageBytes.length} bytes)',
              );
            } else {
              // Fallback to original if compression fails
              final originalBytes = await imageFile.readAsBytes();
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  originalBytes,
                  filename:
                      'delivery_status_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '⚠️ Using original image (compression failed): ${originalBytes.length} bytes',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing delivery status image: $e');
        }
      }

      // Calculate total file size
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.length);
      debugPrint(
        '📦 Total upload size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      debugPrint('📦 Creating delivery status with ${files.length} files');
      debugPrint('⏱️ Starting optimized remote creation...');

      final startTime = DateTime.now();

      final deliveryUpdateRecord = await pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': customerId,
              'title': title,
              'subtitle': subtitle,
              'time': time.toIso8601String(),
              'isAssigned': true,
            },
            files: files,
          );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('⏱️ Remote creation took: ${duration.inMilliseconds}ms');

      debugPrint('✅ Created delivery status: ${deliveryUpdateRecord.id}');

      await pocketBaseClient
          .collection('deliveryData')
          .update(
            customerId,
            body: {
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated customer with new delivery status');
    } catch (e) {
      debugPrint('❌ Failed to create delivery status: $e');
      throw ServerException(
        message: 'Failed to create delivery status: $e',
        statusCode: '500',
      );
    }
  }
}
