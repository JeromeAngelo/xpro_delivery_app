import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class ChecklistDatasource {
  Future<List<ChecklistModel>> getChecklist();
  Future<bool> checkItem(String id);
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);
}

class ChecklistDatasourceImpl implements ChecklistDatasource {
  final PocketBase _pocketBaseClient;
  ChecklistDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;
  @override
  Future<List<ChecklistModel>> getChecklist() async {
    try {
      final records =
          await _pocketBaseClient.collection('checklist').getFullList();
      return records.map((record) {
        final data = {
          ...record.data,
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
        };
        debugPrint('Processing checklist record: $data');
        return ChecklistModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
  @override
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

    final records = await _pocketBaseClient.collection('checklist').getFullList(
      filter: 'trip = "$actualTripId"',
      expand: 'trip',
    );

    debugPrint('✅ Retrieved ${records.length} checklist items from API');

    final checklists = records.map((record) {
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'objectName': record.data['objectName'],
        'isChecked': record.data['isChecked'] ?? false,
        'timeCompleted': record.data['timeCompleted'],
        'trip': actualTripId,
        'expand': {
          'trip': record.expand['trip']?.map((trip) => trip.data).first,
        }
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


  @override
  Future<bool> checkItem(String id) async {
    try {
      final record = await _pocketBaseClient.collection('checklist').getOne(id);
      final currentStatus = record.data['isChecked'] as bool? ?? false;

      final currentTime = DateTime.now().toIso8601String();
      final updatedRecord =
          await _pocketBaseClient.collection('checklist').update(
        id,
        body: {
          'isChecked': !currentStatus,
          'timeCompleted': currentTime,
        },
      );

      return updatedRecord.data['isChecked'] as bool? ?? false;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
