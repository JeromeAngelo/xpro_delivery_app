import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/users_trip_collection/data/models/users_trip_collection_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class UsersTripCollectionRemoteDataSource {
  Future<List<UserTripCollectionModel>> getUserTripCollections(String userId);
}

class UsersTripCollectionRemoteDataSourceImpl
    implements UsersTripCollectionRemoteDataSource {
  final PocketBase _pocketBaseClient;

  UsersTripCollectionRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  @override
  Future<List<UserTripCollectionModel>> getUserTripCollections(
    String userId,
  ) async {
    try {
      debugPrint('🔄 Fetching trip collections for user: $userId');

      // Handle JSON object input
      String actualUserId;
      if (userId.startsWith('{')) {
        final data = jsonDecode(userId);
        actualUserId = data['id'];
      } else {
        actualUserId = userId;
      }

      final result = await _pocketBaseClient
          .collection("usersTripHistory")
          .getFullList(
            filter: 'user = "$actualUserId"',
            expand: "user,trips,trips.personels",
            sort: "-created",
          );

      debugPrint("✅ Retrieved ${result.length} trip collections.");

      return result.map(_mapRecordToUserTripCollection).toList();
    } catch (e) {
      debugPrint("❌ ERROR loading user trip collections: $e");
      throw ServerException(
        message: "Failed to load user trip collections: $e",
        statusCode: "500",
      );
    }
  }

  // -------------------------------------------------------------
  // 🔥 MAIN MAPPER — full model conversion
  // -------------------------------------------------------------
  UserTripCollectionModel _mapRecordToUserTripCollection(RecordModel record) {
    try {
      debugPrint("🔄 Mapping UserTripCollection: ${record.id}");

      // MAP USER from expand
      final userExpanded = _mapExpandedItem(record.expand["user"]);

      // MAP TRIPS (with expand support)
      List<Map<String, dynamic>> tripsList = [];
      final expandedTrips = record.expand["trips"];

      if (expandedTrips != null) {
        for (var t in expandedTrips) {
          final trip = _mapTripRecord(t);
          if (trip != null) tripsList.add(trip);
        }
      }

      final mapped = {
        "id": record.id,
        "collectionId": record.collectionId,
        "collectionName": record.collectionName,
        "isActive": record.data["isActive"] ?? false,
        "created": record.created,
        "updated": record.updated,
        "expand": {
          "user": userExpanded,
          "trips": tripsList,
        }
      };

      return UserTripCollectionModel.fromJson(mapped);
    } catch (e) {
      debugPrint("❌ Error mapping UserTripCollection: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // 🔥 MAP TRIP RECORD + EXPANDED PERSONNEL
  // -------------------------------------------------------------
  Map<String, dynamic>? _mapTripRecord(dynamic record) {
    if (record == null || record is! RecordModel) return null;

    try {
      // Map basic fields
      final map = {
        "id": record.id,
        "collectionId": record.collectionId,
        "collectionName": record.collectionName,
        ...Map<String, dynamic>.from(record.data),
        "created": record.created,
        "updated": record.updated,
      };

      // Map expanded PERSONELS
      if (record.expand.containsKey("personels")) {
        List<Map<String, dynamic>> expandedPersonels = [];

        for (var p in record.expand["personels"] ?? []) {
          final mapped = _mapExpandedItem(p);
          if (mapped != null) expandedPersonels.add(mapped);
        }

        map["expand"] = {
          "personels": expandedPersonels,
        };
      }

      return map;
    } catch (e) {
      debugPrint("⚠️ Error mapping TripModel: $e");
      return null;
    }
  }

  // -------------------------------------------------------------
  // 🔥 GENERIC RECORD EXPAND MAPPER
  // -------------------------------------------------------------
  Map<String, dynamic>? _mapExpandedItem(dynamic record) {
    if (record == null) return null;

    // Expanded list
    if (record is List && record.isNotEmpty) {
      final first = record.first;
      if (first is RecordModel) {
        return {
          "id": first.id,
          "collectionId": first.collectionId,
          "collectionName": first.collectionName,
          ...Map<String, dynamic>.from(first.data),
          "created": first.created,
          "updated": first.updated,
        };
      }
    }

    // Single expanded item
    if (record is RecordModel) {
      return {
        "id": record.id,
        "collectionId": record.collectionId,
        "collectionName": record.collectionName,
        ...Map<String, dynamic>.from(record.data),
        "created": record.created,
        "updated": record.updated,
      };
    }

    return null;
  }
}
