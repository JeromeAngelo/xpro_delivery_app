import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [refreshUserData] implementation for [AuthRemoteDataSrc].
mixin RefreshUserDataImpl on AuthRemoteBase {
  Future<LocalUsersModel> refreshUserData() async {
    try {
      debugPrint('🔄 Refreshing user data');
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData != null) {
        // Parse stored data
        final userData = jsonDecode(storedUserData);
        final userId = userData['id'];

        debugPrint('🔍 Refreshing data for user: $userId');

        final userRecord = await pocketBaseClient
            .collection('users')
            .getOne(
              userId,
              expand:
                  'trip,deliveryTeam,trip.customers,trip.personels,trip.vehicle',
            );

        final mappedData = {
          'id': userRecord.id,
          'collectionId': userRecord.collectionId,
          'collectionName': userRecord.collectionName,
          'email': userRecord.data['email'],
          'name': userRecord.data['name'],
          'tripNumberId': userRecord.data['tripNumberId'],
          'deliveryTeam': mapExpandedRecord(userRecord.expand['deliveryTeam']),
          'trip': mapExpandedRecord(userRecord.expand['trip']),
          'tokenKey': userData['tokenKey'],
        };

        await prefs.setString('user_data', jsonEncode(mappedData));
        debugPrint('✅ User data refreshed successfully');
        return LocalUsersModel.fromJson(mappedData);
      }

      throw const ServerException(
        message: 'No stored user data found',
        statusCode: '404',
      );
    } catch (e) {
      debugPrint('❌ Refresh failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
