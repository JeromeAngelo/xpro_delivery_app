import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [getUserById] implementation for [AuthRemoteDataSrc].
mixin GetUserByIdImpl on AuthRemoteBase {
  Future<LocalUsersModel> getUserById(String userId) async {
    try {
      // Extract actual user ID if we received a JSON object
      String actualUserId;
      if (userId.startsWith('{')) {
        final userData = jsonDecode(userId);
        actualUserId = userData['id'];
      } else {
        actualUserId = userId;
      }

      debugPrint('🔍 Fetching user by ID: $actualUserId');
      debugPrint('📊 Remote Fetch Stats:');

      final user = await pocketBaseClient
          .collection('users')
          .getOne(actualUserId, expand: 'trip,useRole');

      debugPrint('   👤 User Found: ${user.id}');
      debugPrint('   📧 Email: ${user.data['email']}');
      debugPrint('   🚚 Trip Number: ${user.data['tripNumberId']}');

      debugPrint('📦 Expanded Relations:');

      debugPrint(
        '   ✓ Trip: ${user.expand['trip'] != null ? 'Found' : 'Not Found'}',
      );

      final Map<String, dynamic> userData = {
        ...user.data,
        'id': user.id,
        'name': user.data['name'] ?? '',
        'tripNumberId': user.data['tripNumberId'] ?? '',
        'checklist':
            user.expand['checklist']?.map((item) => item.id).toList() ?? [],
        'updateTimeline':
            user.expand['updateTimeline']?.map((item) => item.id).toList() ??
            [],
        'deliveryTeam':
            user.expand['deliveryTeam']?.map((item) => item.id).toList() ?? [],
        'completedCustomer':
            user.expand['completedCustomer']?.map((item) => item.id).toList() ??
            [],
        'returnList':
            user.expand['returnList']?.map((item) => item.id).toList() ?? [],
        'endTripChecklists':
            user.expand['endTripChecklists']?.map((item) => item.id).toList() ??
            [],
        'trip': user.expand['trip'],
      };

      debugPrint('✅ User found and mapped successfully');
      debugPrint('   👤 Name: ${userData['name']}');
      debugPrint('   🎫 Trip Number: ${userData['tripNumberId']}');
      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('❌ User fetch failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
