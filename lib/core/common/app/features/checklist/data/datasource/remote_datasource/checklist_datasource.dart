import 'dart:convert';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:flutter/material.dart';

abstract class ChecklistDatasource {
  // Get all checklists
  Future<List<ChecklistModel>> getAllChecklists();

  // Check/update a specific checklist item
  Future<bool> checkItem(String id);

  // Load checklists by trip ID
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);

  // Create a new checklist item
  Future<ChecklistModel> createChecklistItem({
    required String objectName,
    required bool isChecked,
    String? tripId,
    String? status,
    DateTime? timeCompleted,
  });

  // Update an existing checklist item
  Future<ChecklistModel> updateChecklistItem({
    required String id,
    String? objectName,
    bool? isChecked,
    String? tripId,
    String? status,
    DateTime? timeCompleted,
  });

  // Delete a single checklist item
  Future<bool> deleteChecklistItem(String id);

  // Delete multiple checklist items
  Future<bool> deleteAllChecklistItems(List<String> ids);
}

class ChecklistDatasourceImpl implements ChecklistDatasource {
  final PocketBase _pocketBaseClient;

  ChecklistDatasourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

    @override
Future<List<ChecklistModel>> getAllChecklists() async {
  try {
    debugPrint('🔄 Fetching all checklists');

    final records = await _pocketBaseClient
        .collection('checklist')
        .getFullList(expand: 'trip', sort: '-created'); // latest first

    debugPrint('✅ Successfully fetched ${records.length} checklists');

    List<ChecklistModel> checklists = [];

    for (var record in records) {
      try {
        // Process trip data if available
        TripModel? tripModel;
        String? tripId;
        String? tripNumberId;

        if (record.expand['trip'] != null) {
          final tripData = record.expand['trip'];
          if (tripData is List && tripData!.isNotEmpty) {
            final tripRecord = tripData[0];
            tripId = tripRecord.id;
            tripNumberId = tripRecord.data['tripNumberId'];

            tripModel = TripModel(
              id: tripRecord.id,
              collectionId: tripRecord.collectionId,
              collectionName: tripRecord.collectionName,
              tripNumberId: tripNumberId,
              isAccepted: tripRecord.data['isAccepted'] ?? false,
              isEndTrip: tripRecord.data['isEndTrip'] ?? false,
            );

            debugPrint(
              '✅ Found trip ID: $tripId (Number: $tripNumberId) for checklist: ${record.id}',
            );
          } else if (tripData is String) {
            tripId = tripData as String?;
            try {
              final tripRecord = await _pocketBaseClient
                  .collection('tripticket')
                  .getOne(tripId!);

              tripNumberId = tripRecord.data['tripNumberId'];

              tripModel = TripModel(
                id: tripRecord.id,
                collectionId: tripRecord.collectionId,
                collectionName: tripRecord.collectionName,
                tripNumberId: tripNumberId,
                isAccepted: tripRecord.data['isAccepted'] ?? false,
                isEndTrip: tripRecord.data['isEndTrip'] ?? false,
              );

              debugPrint(
                '✅ Fetched trip details - Number: $tripNumberId for checklist: ${record.id}',
              );
            } catch (e) {
              debugPrint('⚠️ Could not fetch trip details: $e');
            }
          }
        }

        final checklistModel = ChecklistModel(
          id: record.id,
          objectName: record.data['objectName'] ?? '',
          isChecked: record.data['isChecked'] ?? false,
          status: record.data['status'] ?? '',
          timeCompleted: record.data['timeCompleted'] != null
              ? DateTime.tryParse(record.data['timeCompleted'])
              : null,
          tripModel: tripModel,
          tripId: tripId,
        );

        checklists.add(checklistModel);
        debugPrint('✅ Processed checklist: ${record.id} with trip: $tripId');
      } catch (e) {
        debugPrint('❌ Error processing checklist record: ${e.toString()}');
        checklists.add(ChecklistModel(
          id: record.id,
          objectName: record.data['objectName'] ?? '',
          isChecked: record.data['isChecked'] ?? false,
          status: record.data['status'] ?? '',
        ));
      }
    }

    // ✅ Deduplicate by objectName (latest first because of sort: '-created')
    final uniqueChecklists = <String, ChecklistModel>{};
    for (var checklist in checklists) {
      uniqueChecklists.putIfAbsent(checklist.objectName ?? '', () => checklist);
    }

    debugPrint(
      '✨ Unique checklists count: ${uniqueChecklists.values.length} '
      'from original: ${checklists.length}',
    );

    return uniqueChecklists.values.toList();
  } catch (e) {
    debugPrint('❌ Error fetching all checklists: ${e.toString()}');
    throw ServerException(
      message: 'Failed to fetch all checklists: ${e.toString()}',
      statusCode: '500',
    );
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

      final records = await _pocketBaseClient
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

  @override
  Future<bool> checkItem(String id) async {
    try {
      debugPrint('🔄 Checking item: $id');

      final record = await _pocketBaseClient.collection('checklist').getOne(id);
      final currentStatus = record.data['isChecked'] as bool? ?? false;

      final currentTime = DateTime.now().toIso8601String();
      final updatedRecord = await _pocketBaseClient
          .collection('checklist')
          .update(
            id,
            body: {'isChecked': !currentStatus, 'timeCompleted': currentTime},
          );

      debugPrint('✅ Successfully checked item');
      return updatedRecord.data['isChecked'] as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Error checking item: ${e.toString()}');
      throw ServerException(
        message: 'Failed to check item: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<ChecklistModel> createChecklistItem({
    required String objectName,
    required bool isChecked,
    String? tripId,
    String? status,
    DateTime? timeCompleted,
  }) async {
    try {
      debugPrint('🔄 Creating new checklist item: $objectName');

      final body = {
        'objectName': objectName,
        'isChecked': isChecked,
        'status': status ?? 'pending',
      };

      if (tripId != null) {
        body['trip'] = tripId;
      }

      if (timeCompleted != null) {
        body['timeCompleted'] = timeCompleted.toIso8601String();
      }

      final record = await _pocketBaseClient
          .collection('checklist')
          .create(body: body);

      // Get the created record with expanded relations
      final createdRecord = await _pocketBaseClient
          .collection('checklist')
          .getOne(record.id, expand: 'trip');

      debugPrint('✅ Successfully created checklist item with ID: ${record.id}');

      final mappedData = {
        'id': createdRecord.id,
        'collectionId': createdRecord.collectionId,
        'collectionName': createdRecord.collectionName,
        'objectName': createdRecord.data['objectName'] ?? '',
        'isChecked': createdRecord.data['isChecked'] ?? false,
        'status': createdRecord.data['status'] ?? 'pending',
        'timeCompleted': createdRecord.data['timeCompleted'],
        'trip': tripId,
        'expand':
            createdRecord.expand.isNotEmpty &&
                    createdRecord.expand['trip'] != null
                ? {
                  'trip':
                      createdRecord.expand['trip']
                          ?.map((trip) => trip.data)
                          .first,
                }
                : null,
      };

      return ChecklistModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error creating checklist item: ${e.toString()}');
      throw ServerException(
        message: 'Failed to create checklist item: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<ChecklistModel> updateChecklistItem({
    required String id,
    String? objectName,
    bool? isChecked,
    String? tripId,
    String? status,
    DateTime? timeCompleted,
  }) async {
    try {
      debugPrint('🔄 Updating checklist item: $id');

      final body = <String, dynamic>{};

      if (objectName != null) {
        body['objectName'] = objectName;
      }

      if (isChecked != null) {
        body['isChecked'] = isChecked;
      }

      if (tripId != null) {
        body['trip'] = tripId;
      }

      if (status != null) {
        body['status'] = status;
      }

      if (timeCompleted != null) {
        body['timeCompleted'] = timeCompleted.toIso8601String();
      }

      await _pocketBaseClient.collection('checklist').update(id, body: body);

      // Get the updated record with expanded relations
      final updatedRecord = await _pocketBaseClient
          .collection('checklist')
          .getOne(id, expand: 'trip');

      debugPrint('✅ Successfully updated checklist item');

      final mappedData = {
        'id': updatedRecord.id,
        'collectionId': updatedRecord.collectionId,
        'collectionName': updatedRecord.collectionName,
        'objectName': updatedRecord.data['objectName'] ?? '',
        'isChecked': updatedRecord.data['isChecked'] ?? false,
        'status': updatedRecord.data['status'] ?? 'pending',
        'timeCompleted': updatedRecord.data['timeCompleted'],
        'trip': updatedRecord.data['trip'],
        'expand':
            updatedRecord.expand.isNotEmpty &&
                    updatedRecord.expand['trip'] != null
                ? {
                  'trip':
                      updatedRecord.expand['trip']
                          ?.map((trip) => trip.data)
                          .first,
                }
                : null,
      };

      return ChecklistModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error updating checklist item: ${e.toString()}');
      throw ServerException(
        message: 'Failed to update checklist item: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteChecklistItem(String id) async {
    try {
      debugPrint('🔄 Deleting checklist item: $id');

      await _pocketBaseClient.collection('checklist').delete(id);

      debugPrint('✅ Successfully deleted checklist item');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting checklist item: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete checklist item: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> deleteAllChecklistItems(List<String> ids) async {
    try {
      debugPrint('🔄 Deleting multiple checklist items: ${ids.length} items');

      // Use Future.wait to delete all items in parallel
      await Future.wait(
        ids.map((id) => _pocketBaseClient.collection('checklist').delete(id)),
      );

      debugPrint('✅ Successfully deleted all checklist items');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting multiple checklist items: ${e.toString()}');
      throw ServerException(
        message: 'Failed to delete multiple checklist items: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
