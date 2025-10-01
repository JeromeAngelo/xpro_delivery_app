import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../model/user_performance_model.dart';

abstract class UserPerformanceRemoteDatasource {
  const UserPerformanceRemoteDatasource();

  Future<UserPerformanceModel> loadUserPerformanceByUserId(String userId);
  Future<double> calculateDeliveryAccuracy(String userId);
}

class UserPerformanceRemoteDatasourceImpl implements UserPerformanceRemoteDatasource {
  const UserPerformanceRemoteDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<UserPerformanceModel> loadUserPerformanceByUserId(String userId) async {
    try {
      debugPrint('🔄 Loading user performance for user ID: $userId');

      // Query user performance by user ID with expanded user data
      final records = await _pocketBaseClient
          .collection('userPerformance')
          .getFullList(
            filter: 'user = "$userId"',
            expand: 'user',
          );

      if (records.isEmpty) {
        debugPrint('⚠️ No performance data found for user: $userId');
        throw const ServerException(
          message: 'No performance data found for this user',
          statusCode: '404',
        );
      }

      // Get the first record (should be unique per user)
      final record = records.first;
      debugPrint('✅ Found performance record: ${record.id}');

      // Map the record data
      final mappedData = _mapUserPerformanceData(record);
      final userPerformanceModel = UserPerformanceModel.fromJson(mappedData);

      debugPrint('📊 Performance loaded - Total: ${userPerformanceModel.totalDeliveries}, '
          'Successful: ${userPerformanceModel.successfulDeliveries}, '
          'Accuracy: ${userPerformanceModel.deliveryAccuracy}%');

      return userPerformanceModel;
    } catch (e) {
      debugPrint('❌ Error loading user performance: $e');
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to load user performance: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<double> calculateDeliveryAccuracy(String userId) async {
    try {
      debugPrint('🧮 Calculating delivery accuracy for user ID: $userId');

      // Load user performance data
      final userPerformance = await loadUserPerformanceByUserId(userId);

      // Extract values
      final totalDeliveries = userPerformance.totalDeliveries ?? 0.0;
      final successfulDeliveries = userPerformance.successfulDeliveries ?? 0.0;

      debugPrint('📊 Calculation data - Total: $totalDeliveries, Successful: $successfulDeliveries');

      // Calculate accuracy: (successfulDeliveries / totalDeliveries) * 100
      double accuracy = 0.0;
      if (totalDeliveries > 0) {
        accuracy = (successfulDeliveries / totalDeliveries) * 100;
      }

      debugPrint('✅ Calculated delivery accuracy: ${accuracy.toStringAsFixed(2)}%');

      // Update the accuracy in the database if it's different
      if (userPerformance.deliveryAccuracy != accuracy) {
        await _updateDeliveryAccuracy(userPerformance.id!, accuracy);
        debugPrint('📝 Updated accuracy in database');
      }

      return accuracy;
    } catch (e) {
      debugPrint('❌ Error calculating delivery accuracy: $e');
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to calculate delivery accuracy: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to update delivery accuracy in the database
  Future<void> _updateDeliveryAccuracy(String performanceId, double accuracy) async {
    try {
      await _pocketBaseClient.collection('userPerformance').update(
        performanceId,
        body: {
          'deliveryAccuracy': accuracy,
          'updated': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('✅ Successfully updated delivery accuracy in database');
    } catch (e) {
      debugPrint('⚠️ Failed to update accuracy in database: $e');
      // Don't throw here as the calculation was successful
    }
  }

  // Helper method to map PocketBase record to our data structure
  DataMap _mapUserPerformanceData(dynamic record) {
    try {
      final data = <String, dynamic>{
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'totalDeliveries': _parseDouble(record.data['totalDeliveries']),
        'successfulDeliveries': _parseDouble(record.data['successfulDeliveries']),
        'cancelledDeliveries': _parseDouble(record.data['cancelledDeliveries']),
        'deliveryAccuracy': _parseDouble(record.data['deliveryAccuracy']),
        'created': record.created,
        'updated': record.updated,
        'user': record.data['user'],
      };

      // Handle expanded user data
      if (record.expand != null && record.expand['user'] != null) {
        data['expand'] = {
          'user': record.expand['user'],
        };
      }

      return data;
    } catch (e) {
      debugPrint('❌ Error mapping user performance data: $e');
      throw ServerException(
        message: 'Failed to map user performance data: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    } catch (e) {
      debugPrint('⚠️ Error parsing double value: $e');
      return null;
    }
  }
}
