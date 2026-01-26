import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/sync_status_enums.dart';

@Entity()
class DeliveryUpdateModel extends DeliveryUpdateEntity {
  // ---------------------------------------------------
  // OBJECTBOX
  // ---------------------------------------------------
  @Id(assignable: true)
  int objectBoxId = 0;

  // ---------------------------------------------------
  // POCKETBASE CORE
  // ---------------------------------------------------

  /// PocketBase record ID (set AFTER remote sync)
  @override
  @Property()
  String? id;

  @override
  @Property()
  String? collectionId;

  @override
  @Property()
  String? collectionName;

  // ---------------------------------------------------
  // REQUIRED FOR REMOTE SYNC (🚨 DO NOT REMOVE)
  // ---------------------------------------------------

  /// PocketBase ID of DeliveryData (foreign key)
  @Property()
  String? deliveryDataPbId;

  /// PocketBase ID of DeliveryStatusChoice
  @Property()
  String? statusChoicePbId;

  // ---------------------------------------------------
  // DISPLAY / BUSINESS DATA
  // ---------------------------------------------------
  @override
  @Property()
  String? title;

  @override
  @Property()
  String? subtitle;

  @override
  @Property(type: PropertyType.date)
  DateTime? time;

  @override
  @Property(type: PropertyType.date)
  DateTime? created;

  @override
  @Property(type: PropertyType.date)
  DateTime? updated;

  /// Local timestamp for last local update (used to prefer local changes
  /// over incoming watched items that may be missing transient data)
  @Property(type: PropertyType.date)
  DateTime? lastLocalUpdatedAt;

  @override
  @Property()
  bool? isAssigned;

  @override
  @Property()
  String? assignedTo;

  @override
  @Property()
  String? remarks;

  @override
  @Property()
  String? image;

  @override
  @Property()
  String? customer;

  // ---------------------------------------------------
  // SYNC CONTROL (🚨 REQUIRED)
  // ---------------------------------------------------
  @Property()
  String syncStatus = SyncStatus.pending.name;

  @Property()
  int retryCount = 0;

  // ---------------------------------------------------
  // RELATIONS (LOCAL ONLY)
  // ---------------------------------------------------
  @override
  final deliveryData = ToOne<DeliveryDataModel>();

  // ---------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------
  DeliveryUpdateModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.deliveryDataPbId,
    this.statusChoicePbId,
    this.title,
    this.subtitle,
    this.time,
    this.created,
    this.updated,
    this.lastLocalUpdatedAt,
    this.isAssigned,
    this.assignedTo,
    this.remarks,
    this.image,
    this.customer,
    this.syncStatus = 'pending',
    this.retryCount = 0,
    DeliveryDataModel? deliveryDataModel,
    this.objectBoxId = 0,
  }) {
    if (deliveryDataModel != null) {
      deliveryData.target = deliveryDataModel;
    }
  }

  // ---------------------------------------------------
  // FROM JSON (REMOTE → LOCAL)
  // ---------------------------------------------------
  factory DeliveryUpdateModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        debugPrint('📅 Failed to parse date → $value');
        return null;
      }
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    final expanded = json['expand'] as Map<String, dynamic>?;
    DeliveryDataModel? deliveryDataModel;

    if (expanded?['deliveryData'] is Map<String, dynamic>) {
      deliveryDataModel = DeliveryDataModel.fromJson(expanded!['deliveryData']);
    }

    return DeliveryUpdateModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString() ?? 'delivery_updates',
      deliveryDataPbId: json['deliveryData']?.toString(),
      statusChoicePbId: json['statusChoice']?.toString(),
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      time: parseDate(json['time']),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
      lastLocalUpdatedAt:
          parseDate(json['lastLocalUpdatedAt']) ?? parseDate(json['updated']),
      isAssigned: parseBool(json['isAssigned']),
      assignedTo: json['assignedTo']?.toString(),
      remarks: json['remarks']?.toString(),
      image: json['image']?.toString(),
      customer: json['customer']?.toString(),
      syncStatus: SyncStatus.synced.name,
      retryCount: 0,
      deliveryDataModel: deliveryDataModel,
    );
  }

  /// --- To JSON ---
  DataMap toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'title': title,
      'subtitle': subtitle,
      'time': time?.toIso8601String(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'lastLocalUpdatedAt': lastLocalUpdatedAt?.toIso8601String(),
      'isAssigned': isAssigned,
      'assignedTo': assignedTo,
      'remarks': remarks,
      'image': image,
      'customer': customer,
      'deliveryData': deliveryData.target?.id,
    };
  }

  /// --- Initial Factory ---
  factory DeliveryUpdateModel.initial([String? customerId]) {
    final now = DateTime.now();
    return DeliveryUpdateModel(
      id: '',
      collectionId: '',
      collectionName: 'delivery_update',
      title: 'Pending',
      subtitle: 'Waiting to Accept the Trip',
      time: now,
      created: now,
      updated: now,
      lastLocalUpdatedAt: now,
      isAssigned: false,
      assignedTo: null,
      remarks: '',
      image: null,
      customer: customerId,
    );
  }

  /// --- Copy With ---
  DeliveryUpdateModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? title,
    String? subtitle,
    DateTime? time,
    DateTime? created,
    DateTime? updated,
    DateTime? lastLocalUpdatedAt,
    bool? isAssigned,
    String? assignedTo,
    String? remarks,
    String? image,
    String? customer,
     String? syncStatus,
    DeliveryDataModel? deliveryDataModel,
     int? retryCount,
    DateTime? lastSyncAttemptAt,
    DateTime? nextRetryAt,
    String? lastSyncError,
    
  }) {
    final model = DeliveryUpdateModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      lastLocalUpdatedAt: lastLocalUpdatedAt ?? this.lastLocalUpdatedAt,
      isAssigned: isAssigned ?? this.isAssigned,
      assignedTo: assignedTo ?? this.assignedTo,
      remarks: remarks ?? this.remarks,
      image: image ?? this.image,
      customer: customer ?? this.customer,
      objectBoxId: objectBoxId,
       syncStatus: syncStatus ?? this.syncStatus,
    );

    if (deliveryDataModel != null) {
      model.deliveryData.target = deliveryDataModel;
    } else if (deliveryData.target != null) {
      model.deliveryData.target = deliveryData.target;
    }

    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryUpdateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryUpdateModel(id: $id, title: $title, customer: $customer, deliveryData: ${deliveryData.target?.id})';
  }
}
