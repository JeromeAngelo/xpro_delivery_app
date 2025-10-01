import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

@Entity()
class UserPerformanceEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<LocalUsersModel> user = ToOne<LocalUsersModel>();

  // Performance metrics
  final double? totalDeliveries;
  final double? successfulDeliveries;
  final double? cancelledDeliveries;
  final double? deliveryAccuracy;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  UserPerformanceEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    LocalUsersModel? userData,
    this.totalDeliveries,
    this.successfulDeliveries,
    this.cancelledDeliveries,
    this.deliveryAccuracy,
    this.created,
    this.updated,
  }) {
    if (userData != null) user.target = userData;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    user.target?.id,
    totalDeliveries,
    successfulDeliveries,
    cancelledDeliveries,
    deliveryAccuracy,
    created,
    updated,
  ];

  // Helper method to calculate delivery accuracy percentage
  double get deliveryAccuracyPercentage {
    if (totalDeliveries == null || totalDeliveries == 0) return 0.0;
    if (successfulDeliveries == null) return 0.0;
    return (successfulDeliveries! / totalDeliveries!) * 100;
  }

  // Helper method to calculate cancellation rate
  double get cancellationRate {
    if (totalDeliveries == null || totalDeliveries == 0) return 0.0;
    if (cancelledDeliveries == null) return 0.0;
    return (cancelledDeliveries! / totalDeliveries!) * 100;
  }

  // Helper method to get success rate
  double get successRate {
    if (totalDeliveries == null || totalDeliveries == 0) return 0.0;
    if (successfulDeliveries == null) return 0.0;
    return (successfulDeliveries! / totalDeliveries!) * 100;
  }

  // Helper method to check if performance is good
  bool get hasGoodPerformance {
    return deliveryAccuracyPercentage >= 80.0;
  }

  // Helper method to get performance status
  String get performanceStatus {
    final accuracy = deliveryAccuracyPercentage;
    if (accuracy >= 95.0) return 'Excellent';
    if (accuracy >= 85.0) return 'Good';
    if (accuracy >= 70.0) return 'Average';
    if (accuracy >= 50.0) return 'Below Average';
    return 'Poor';
  }

  // Helper method to get user name
  String get userName => user.target?.name ?? 'Unknown User';

  // Helper method to get user email
  String get userEmail => user.target?.email ?? 'No Email';

  // Factory constructor for creating an empty entity
  factory UserPerformanceEntity.empty() {
    return UserPerformanceEntity(
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

  @override
  String toString() {
    return 'UserPerformanceEntity('
        'id: $id, '
        'user: ${user.target?.name}, '
        'totalDeliveries: $totalDeliveries, '
        'successfulDeliveries: $successfulDeliveries, '
        'cancelledDeliveries: $cancelledDeliveries, '
        'deliveryAccuracy: $deliveryAccuracy, '
        'created: $created'
        ')';
  }
}
