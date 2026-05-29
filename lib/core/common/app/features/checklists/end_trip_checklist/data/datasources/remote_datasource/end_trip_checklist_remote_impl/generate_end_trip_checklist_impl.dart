import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_impl/end_trip_checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GenerateEndTripChecklistImpl on EndTripChecklistRemoteBase {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(
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

      // Check for existing checklists
      final existingChecklists = await pocketBaseClient
          .collection('endTripChecklist')
          .getList(filter: 'trip = "$actualTripId"');

      if (existingChecklists.items.isNotEmpty) {
        debugPrint('📝 Found existing checklists, returning those');
        return existingChecklists.items
            .map((record) => EndTripChecklistModel.fromJson(record.toJson()))
            .toList();
      }

      // Create new checklist items with trip reference
      final checklistItems = [
        {
          'trip': actualTripId,
          'objectName': 'Collections',
          'isChecked': false,
          'status': 'pending',
          'description': 'Check all the collections',
          'created': DateTime.now().toIso8601String(),
        },
        {
          'trip': actualTripId,
          'objectName': 'Pushcarts',
          'description': 'Check all the pushcarts',
          'isChecked': false,
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
        },
        {
          'trip': actualTripId,
          'objectName': 'Remittance',
          'description': 'Check all the remittances',
          'isChecked': false,
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
        },
      ];

      debugPrint('📝 Creating new checklist items');
      final createdItems = await Future.wait(
        checklistItems.map((item) async {
          final response = await pocketBaseClient
              .collection('endTripChecklist')
              .create(body: item);
          debugPrint('✅ Created item: ${response.id}');
          return response;
        }),
      );

      // Update tripticket with checklist references
      final checklistIds = createdItems.map((item) => item.id).toList();
      await pocketBaseClient
          .collection('tripticket')
          .update(actualTripId, body: {'endTripChecklists': checklistIds});
      debugPrint('✅ Updated tripticket with checklist IDs: $checklistIds');

      return createdItems
          .map((record) => EndTripChecklistModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Remote: Generation failed - ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
