import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';

import '../../../../../../enums/sync_status_enums.dart';
@Entity()
class DeliveryStatusChoicesModel extends DeliveryStatusChoicesEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  @override
  @Property()
  String? id;

  @override
  @Property()
  String? collectionId;

  @override
  @Property()
  String? collectionName;

  @override
  @Property()
  String? title;

  @override
  @Property()
  String? subtitle;

  @override
  @Property()
  DateTime? created;

  @override
  @Property()
  DateTime? updated;

   /// NEW: link to deliveryData
  @Property()
  String? deliveryDataId;

  // --------------------------------------------------------------------------
  // 🔵 BACKGROUND SYNC FIELDS
  // --------------------------------------------------------------------------

  @Property()
  String syncStatus = SyncStatus.pending.name; // pending, syncing, synced, failed

  @Property()
  int retryCount = 0; // retry counter for backoff

  @Property()
  DateTime? lastSyncAttemptAt; // last attempt timestamp

  @Property()
  DateTime? nextRetryAt; // scheduled next retry

  @Property()
  String? lastSyncError; // error message from last attempt

  @Property()
  DateTime? lastLocalUpdatedAt; // local timestamp for conflict resolution

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
DeliveryStatusChoicesModel({
  this.id,
  this.collectionId,
  this.collectionName,
  this.title,
  this.subtitle,
  this.created,
  this.deliveryDataId,
  this.updated,
  String? syncStatus, // nullable
  this.retryCount = 0,
  this.lastSyncAttemptAt,
  this.nextRetryAt,
  this.lastSyncError,
  this.lastLocalUpdatedAt,
  this.objectBoxId = 0,
}) : syncStatus = syncStatus ?? SyncStatus.pending.name; // initialize here


  // --------------------------------------------------------------------------
  // 🔵 PARSE HELPERS
  // --------------------------------------------------------------------------
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      debugPrint('📅 Failed to parse date → fallback: null');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // 🔵 FROM JSON
  // --------------------------------------------------------------------------
  factory DeliveryStatusChoicesModel.fromJson(dynamic json) {
    return DeliveryStatusChoicesModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString() ?? 'delivery_status_choices',
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
      syncStatus: json['syncStatus']?.toString() ?? SyncStatus.pending.name,
      retryCount: json['retryCount'] ?? 0,
      lastSyncAttemptAt: parseDate(json['lastSyncAttemptAt']),
      nextRetryAt: parseDate(json['nextRetryAt']),
      lastSyncError: json['lastSyncError']?.toString(),
      lastLocalUpdatedAt: parseDate(json['lastLocalUpdatedAt']),
    );
  }

  // --------------------------------------------------------------------------
  // 🔵 TO JSON
  // --------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'title': title,
      'subtitle': subtitle,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'syncStatus': syncStatus,
      'retryCount': retryCount,
      'lastSyncAttemptAt': lastSyncAttemptAt?.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'lastSyncError': lastSyncError,
      'lastLocalUpdatedAt': lastLocalUpdatedAt?.toIso8601String(),
    };
  }

  // --------------------------------------------------------------------------
  // 🔵 INITIAL FACTORY
  // --------------------------------------------------------------------------
  factory DeliveryStatusChoicesModel.initial() {
    final now = DateTime.now();
    return DeliveryStatusChoicesModel(
      id: '',
      collectionId: '',
      collectionName: 'delivery_status_choices',
      title: '',
      subtitle: '',
      created: now,
      updated: now,
      syncStatus: SyncStatus.pending.name,
      retryCount: 0,
      lastSyncAttemptAt: now,
      nextRetryAt: now,
      lastSyncError: null,
      lastLocalUpdatedAt: now,
    );
  }

  // --------------------------------------------------------------------------
  // 🔵 COPY WITH
  // --------------------------------------------------------------------------
  DeliveryStatusChoicesModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? title,
    String? subtitle,
    DateTime? created,
    DateTime? updated,
    String? syncStatus,
    int? retryCount,
    DateTime? lastSyncAttemptAt,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? lastLocalUpdatedAt,
  }) {
    return DeliveryStatusChoicesModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      lastLocalUpdatedAt: lastLocalUpdatedAt ?? this.lastLocalUpdatedAt,
      objectBoxId: objectBoxId,
    );
  }

  // --------------------------------------------------------------------------
  // 🔵 EQUALITY + HASH
  // --------------------------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryStatusChoicesModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryStatusChoicesModel(id: $id, title: $title, syncStatus: $syncStatus, retryCount: $retryCount)';
  }
}


