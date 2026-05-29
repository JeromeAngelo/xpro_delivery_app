import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/model/delivery_status_choices_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/data/datasources/remote_datasource/delivery_status_choices_remote_impl/delivery_status_choices_remote_base.dart';
import '../../../../../../../../errors/exceptions.dart';

mixin SyncAllDeliveryStatusChoicesImpl on DeliveryStatusChoicesRemoteBase {
  Future<List<DeliveryStatusChoicesModel>>
  syncAllDeliveryStatusChoices() async {
    try {
      debugPrint('🔄 [SYNC] Starting sync of ALL delivery status choices...');

      // 1️⃣ Fetch all records from PocketBase
      final records = await pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFullList(expand: '');

      if (records.isEmpty) {
        debugPrint('⚠️ No delivery status choices found in remote collection.');
        return [];
      }

      debugPrint('📦 Found ${records.length} delivery status choices.');

      // 2️⃣ Convert each PocketBase record → DeliveryStatusChoicesModel
      final choices =
          records.map((record) {
            final json = record.toJson();

            final model = DeliveryStatusChoicesModel(
              id: json['id']?.toString(),
              collectionId: json['collectionId']?.toString(),
              collectionName:
                  json['collectionName']?.toString() ?? 'deliveryStatusChoices',
              title: json['title']?.toString(),
              subtitle: json['subtitle']?.toString(),
              created:
                  json['created'] != null
                      ? DateTime.tryParse(json['created'])
                      : null,
              updated:
                  json['updated'] != null
                      ? DateTime.tryParse(json['updated'])
                      : null,
            );

            debugPrint(
              '   • Synced Status: ${model.title} | Subtitle: ${model.subtitle} | ID: ${model.id}',
            );

            return model;
          }).toList();

      debugPrint(
        '✅ [SYNC COMPLETE] Synced ${choices.length} delivery status choices.',
      );
      return choices;
    } catch (e) {
      debugPrint('❌ [SYNC ERROR] Failed to sync delivery status choices: $e');
      throw ServerException(
        message: 'Failed to sync delivery status choices: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
