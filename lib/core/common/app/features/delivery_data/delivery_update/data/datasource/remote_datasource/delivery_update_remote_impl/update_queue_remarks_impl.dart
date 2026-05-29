import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateQueueRemarksImpl on DeliveryUpdateRemoteBase {
  Future<void> updateQueueRemarks(
    String statusId,
    String remarks,
    String image,
  ) async {
    try {
      debugPrint('📝 Updating queue remarks for status: $statusId');
      final files = <MultipartFile>[];

      // 🔽 Process image if provided
      if (image.isNotEmpty) {
        try {
          final imageFile = File(image);
          if (await imageFile.exists()) {
            debugPrint('📸 Processing status update image...');

            final compressedImageBytes = await compressImageToSmallSize(image);
            if (compressedImageBytes != null) {
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  compressedImageBytes,
                  filename:
                      'status_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '✅ Added compressed image (${compressedImageBytes.length} bytes)',
              );
            } else {
              // fallback to original if compression fails
              final originalBytes = await imageFile.readAsBytes();
              files.add(
                MultipartFile.fromBytes(
                  'image',
                  originalBytes,
                  filename:
                      'status_update_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
                ),
              );
              debugPrint(
                '⚠️ Using original image (compression failed): ${originalBytes.length} bytes',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing image: $e');
        }
      }

      // 🔽 Perform update call to PocketBase (deliveryUpdate collection)
      await pocketBaseClient
          .collection('deliveryUpdate')
          .update(statusId, body: {'remarks': remarks}, files: files);

      debugPrint('✅ Queue remarks successfully updated for status $statusId');
    } catch (e) {
      debugPrint('❌ Failed to update queue remarks: $e');
      throw ServerException(message: e.toString(), statusCode: '404');
    }
  }
}
