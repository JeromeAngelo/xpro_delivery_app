import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_impl/end_trip_checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadEndTripChecklistImpl on EndTripChecklistRemoteBase {
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(
    String tripId,
  ) async {
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
          .collection('endTripChecklist')
          .getFullList(filter: 'trip = "$actualTripId"', expand: 'trip');

      debugPrint('✅ Retrieved ${records.length} end trip checklist items');

      final checklists =
          records.map((record) {
            final mappedData = {
              'id': record.id,
              'collectionId': record.collectionId,
              'collectionName': record.collectionName,
              'objectName': record.data['objectName'] ?? '',
              'isChecked': record.data['isChecked'] ?? false,
              'status': record.data['status'] ?? 'pending',
              'timeCompleted': record.data['timeCompleted'],
              'description': record.data['description'] ?? '',
              'trip': actualTripId,
              'expand': {
                'trip': record.expand['trip']?.map((trip) => trip.data).first,
              },
            };
            return EndTripChecklistModel.fromJson(mappedData);
          }).toList();

      debugPrint(
        '✨ Successfully mapped ${checklists.length} end trip checklist items',
      );
      return checklists;
    } catch (e) {
      debugPrint('❌ End trip checklist fetch failed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load end trip checklist: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
