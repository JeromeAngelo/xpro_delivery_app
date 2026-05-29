import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/remote_datasource/checklist_remote_impl/checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadChecklistByTripIdImpl on ChecklistRemoteBase {
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId) async {
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

      final records = await pocketBaseClient
          .collection('checklist')
          .getFullList(filter: 'trip = "$actualTripId"', expand: 'trip');

      debugPrint('✅ Retrieved ${records.length} checklist items from API');

      final checklists =
          records.map((record) {
            final mappedData = {
              'id': record.id,
              'collectionId': record.collectionId,
              'collectionName': record.collectionName,
              'objectName': record.data['objectName'],
              'description': record.data['description'],
              'isChecked': record.data['isChecked'] ?? false,
              'timeCompleted': record.data['timeCompleted'],
              'trip': actualTripId,
              'expand': {
                'trip': record.expand['trip']?.map((trip) => trip.data).first,
              },
            };
            return ChecklistModel.fromJson(mappedData);
          }).toList();

      debugPrint('✨ Successfully mapped ${checklists.length} checklist items');
      return checklists;
    } catch (e) {
      debugPrint('❌ Checklist fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load checklist: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
