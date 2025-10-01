import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/domain/entity/user_performance_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

@Entity()
class UserPerformanceModel extends UserPerformanceEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String? userId;

  UserPerformanceModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    super.userData,
    super.totalDeliveries,
    super.successfulDeliveries,
    super.cancelledDeliveries,
    super.deliveryAccuracy,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    userId = userData?.id;

  factory UserPerformanceModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse double values safely
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      try {
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      } catch (e) {
        debugPrint('❌ Error parsing double value: $e');
        return null;
      }
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;
    
    // Process user relation
    LocalUsersModel? userModel;
    if (expandedData != null && expandedData.containsKey('user')) {
      final userData = expandedData['user'];
      if (userData != null) {
        if (userData is RecordModel) {
          userModel = LocalUsersModel.fromJson({
            'id': userData.id,
            'collectionId': userData.collectionId,
            'collectionName': userData.collectionName,
            ...userData.data,
            'expand': userData.expand,
          });
        } else if (userData is Map) {
          userModel = LocalUsersModel.fromJson(userData as DataMap);
        }
      }
    } else if (json['user'] != null) {
      // If not expanded, just store the ID
      userModel = LocalUsersModel(id: json['user'].toString());
    }

    return UserPerformanceModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      userData: userModel,
      totalDeliveries: parseDouble(json['totalDeliveries']),
      successfulDeliveries: parseDouble(json['successfulDeliveries']),
      cancelledDeliveries: parseDouble(json['cancelledDeliveries']),
      deliveryAccuracy: parseDouble(json['deliveryAccuracy']),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'user': user.target?.id,
      'totalDeliveries': totalDeliveries,
      'successfulDeliveries': successfulDeliveries,
      'cancelledDeliveries': cancelledDeliveries,
      'deliveryAccuracy': deliveryAccuracy,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  UserPerformanceModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    LocalUsersModel? userData,
    double? totalDeliveries,
    double? successfulDeliveries,
    double? cancelledDeliveries,
    double? deliveryAccuracy,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = UserPerformanceModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      successfulDeliveries: successfulDeliveries ?? this.successfulDeliveries,
      cancelledDeliveries: cancelledDeliveries ?? this.cancelledDeliveries,
      deliveryAccuracy: deliveryAccuracy ?? this.deliveryAccuracy,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
    
    // Handle user relation
    if (userData != null) {
      model.user.target = userData;
    } else if (user.target != null) {
      model.user.target = user.target;
    }
    
    return model;
  }

  // Factory constructor from entity
  factory UserPerformanceModel.fromEntity(UserPerformanceEntity entity) {
    return UserPerformanceModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      userData: entity.user.target,
      totalDeliveries: entity.totalDeliveries,
      successfulDeliveries: entity.successfulDeliveries,
      cancelledDeliveries: entity.cancelledDeliveries,
      deliveryAccuracy: entity.deliveryAccuracy,
      created: entity.created,
      updated: entity.updated,
    );
  }

  // Factory constructor for creating an empty model
  factory UserPerformanceModel.empty() {
    return UserPerformanceModel(
      id: '',
      collectionId: '',
      collectionName: '',
      userData: null,
      totalDeliveries: 0.0,
      successfulDeliveries: 0.0,
      cancelledDeliveries: 0.0,
      deliveryAccuracy: 0.0,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
  }

  // Method to calculate and update delivery accuracy
  UserPerformanceModel calculateAccuracy() {
    double? newAccuracy;
    if (totalDeliveries != null && totalDeliveries! > 0 && successfulDeliveries != null) {
      newAccuracy = (successfulDeliveries! / totalDeliveries!) * 100;
    }
    
    return copyWith(
      deliveryAccuracy: newAccuracy,
      updated: DateTime.now(),
    );
  }

  // Method to add a delivery
  UserPerformanceModel addDelivery({
    required bool isSuccessful,
    bool isCancelled = false,
  }) {
    final newTotal = (totalDeliveries ?? 0) + 1;
    final newSuccessful = isSuccessful 
        ? (successfulDeliveries ?? 0) + 1 
        : (successfulDeliveries ?? 0);
    final newCancelled = isCancelled 
        ? (cancelledDeliveries ?? 0) + 1 
        : (cancelledDeliveries ?? 0);

    return copyWith(
      totalDeliveries: newTotal,
      successfulDeliveries: newSuccessful,
      cancelledDeliveries: newCancelled,
      updated: DateTime.now(),
    ).calculateAccuracy();
  }

  // Method to reset performance metrics
  UserPerformanceModel resetMetrics() {
    return copyWith(
      totalDeliveries: 0.0,
      successfulDeliveries: 0.0,
      cancelledDeliveries: 0.0,
      deliveryAccuracy: 0.0,
      updated: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPerformanceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserPerformanceModel('
        'id: $id, '
        'user: ${user.target?.name}, '
        'totalDeliveries: $totalDeliveries, '
        'successfulDeliveries: $successfulDeliveries, '
        'cancelledDeliveries: $cancelledDeliveries, '
        'deliveryAccuracy: $deliveryAccuracy, '
        'performanceStatus: $performanceStatus'
        ')';
  }
}
