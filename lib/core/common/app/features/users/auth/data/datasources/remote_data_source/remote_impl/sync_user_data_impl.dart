import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [syncUserData] implementation for [AuthRemoteDataSrc].
mixin SyncUserDataImpl on AuthRemoteBase {
  Future<LocalUsersModel> syncUserData(String userId) async {
    try {
      debugPrint('🔄 Syncing user data from remote for ID: $userId');

      final userRecord = await pocketBaseClient
          .collection('users')
          .getOne(
            userId,
            expand:
                'checklist,updateTimeline,deliveryTeam,completedCustomer,returnList,endTripChecklists,trips',
          );

      // Basic info
      debugPrint('📊 Remote Sync Stats:');
      debugPrint('   👤 User ID: ${userRecord.id}');
      debugPrint('   📝 Name: ${userRecord.data['name']}');
      debugPrint('   📧 Email: ${userRecord.data['email']}');
      debugPrint('   🚚 Trip Number: ${userRecord.data['tripNumberId']}');

      // Expanded relationships counts
      debugPrint(
        '   📋 Checklist Items: ${userRecord.expand['checklist']?.length ?? 0}',
      );
      debugPrint(
        '   ⏱ Update Timeline Items: ${userRecord.expand['updateTimeline']?.length ?? 0}',
      );
      debugPrint(
        '   👥 Delivery Team Items: ${userRecord.expand['deliveryTeam']?.length ?? 0}',
      );
      debugPrint(
        '   ✅ Completed Customers: ${userRecord.expand['completedCustomer']?.length ?? 0}',
      );
      debugPrint(
        '   🔄 Return List Items: ${userRecord.expand['returnList']?.length ?? 0}',
      );
      debugPrint(
        '   🏁 End Trip Checklists: ${userRecord.expand['endTripChecklists']?.length ?? 0}',
      );
      debugPrint('   🛣 Trip Data: ${userRecord.expand['trip'] ?? 'No Trip'}');

      // 4️⃣ Extract DeliveryTeam + nested relations
      final tripRecord = userRecord.expand['trip']?.firstOrNull;
      Map<String, dynamic>? tripMapped;
      if (tripRecord != null) {
        debugPrint('trip record: ${tripRecord.id}');
      }
      final Map<String, dynamic> userData = {
        ...userRecord.data,
        'id': userRecord.id,
        'name': userRecord.data['name'] ?? '',
        'tripNumberId': userRecord.data['tripNumberId'] ?? '',
        'checklist':
            userRecord.expand['checklist']?.map((item) => item.id).toList() ??
            [],
        'updateTimeline':
            userRecord.expand['updateTimeline']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'deliveryTeam':
            userRecord.expand['deliveryTeam']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'completedCustomer':
            userRecord.expand['completedCustomer']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'returnList':
            userRecord.expand['returnList']?.map((item) => item.id).toList() ??
            [],
        'endTripChecklists':
            userRecord.expand['endTripChecklists']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'trip': tripMapped,
      };

      // Full data debug
      debugPrint('📦 Full userData Map: ${userData.toString()}');

      debugPrint('✅ User data synced successfully');
      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('❌ User sync failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
