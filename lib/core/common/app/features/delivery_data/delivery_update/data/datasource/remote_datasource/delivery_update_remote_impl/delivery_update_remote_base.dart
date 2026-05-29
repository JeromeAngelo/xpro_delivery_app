import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';

abstract class DeliveryUpdateRemoteBase {
  final PocketBase pocketBaseClient;

  DeliveryUpdateRemoteBase({required this.pocketBaseClient});

  List<DeliveryUpdateModel> filterStatusChoices(
    List<RecordModel> allStatuses,
    List<String> allowedTitles,
  ) {
    return allStatuses
        .where(
          (status) => allowedTitles.contains(
            status.data['title'].toString().toLowerCase(),
          ),
        )
        .map((record) {
          final statusId = record.id;
          debugPrint(
            '🏷️ Processing status - ID: $statusId, Title: ${record.data['title']}',
          );

          return DeliveryUpdateModel.fromJson({
            'id': statusId, // Explicit ID assignment
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'title': record.data['title'],
            'subtitle': record.data['subtitle'],
          });
        })
        .toList();
  }

  Future<Uint8List?> compressImageToSmallSize(String imagePath) async {
    try {
      debugPrint(
        '🗜️ Compressing delivery status image to very small size: $imagePath',
      );

      // First compression pass - aggressive settings for very small file size
      final firstPassBytes = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: 50, // Lower quality for smaller size
        minWidth: 600, // Smaller max width
        minHeight: 400, // Smaller max height
        format: CompressFormat.jpeg,
      );

      if (firstPassBytes == null) {
        debugPrint('❌ First compression pass failed');
        return null;
      }

      // Check if we need a second pass for even smaller size
      const maxSizeBytes = 500 * 1024; // 500KB max
      if (firstPassBytes.length > maxSizeBytes) {
        debugPrint(
          '🔄 File still too large (${firstPassBytes.length} bytes), applying second compression pass...',
        );

        // Create temporary file for second pass
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/temp_delivery_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(firstPassBytes);

        // Second compression pass - even more aggressive
        final secondPassBytes = await FlutterImageCompress.compressWithFile(
          tempFile.path,
          quality: 30, // Very low quality
          minWidth: 400, // Even smaller dimensions
          minHeight: 300,
          format: CompressFormat.jpeg,
        );

        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('⚠️ Failed to delete temp file: $e');
        }

        if (secondPassBytes != null) {
          final originalSize = await File(imagePath).length();
          debugPrint(
            '📊 Delivery status image compressed (2 passes): $originalSize bytes -> ${secondPassBytes.length} bytes',
          );
          debugPrint(
            '📉 Compression ratio: ${((originalSize - secondPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
          );
          return secondPassBytes;
        } else {
          debugPrint(
            '⚠️ Second compression pass failed, using first pass result',
          );
          final originalSize = await File(imagePath).length();
          debugPrint(
            '📊 Delivery status image compressed (1 pass): $originalSize bytes -> ${firstPassBytes.length} bytes',
          );
          debugPrint(
            '📉 Compression ratio: ${((originalSize - firstPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
          );
          return firstPassBytes;
        }
      } else {
        final originalSize = await File(imagePath).length();
        debugPrint(
          '📊 Delivery status image compressed: $originalSize bytes -> ${firstPassBytes.length} bytes',
        );
        debugPrint(
          '📉 Compression ratio: ${((originalSize - firstPassBytes.length) / originalSize * 100).toStringAsFixed(1)}%',
        );
        return firstPassBytes;
      }
    } catch (e) {
      debugPrint('⚠️ Delivery status image compression failed: $e');
      // Fallback to original file
      try {
        final originalBytes = await File(imagePath).readAsBytes();
        debugPrint(
          '📄 Using original image file: ${originalBytes.length} bytes',
        );
        return originalBytes;
      } catch (fallbackError) {
        debugPrint('❌ Failed to read original image file: $fallbackError');
        return null;
      }
    }
  }
}
