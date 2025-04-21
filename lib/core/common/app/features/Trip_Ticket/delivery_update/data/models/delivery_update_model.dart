import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

@Entity()
class DeliveryUpdateModel extends DeliveryUpdateEntity {
  @Id()
  int objectBoxId = 0;
  @Property()
  String pocketbaseId; // Add this field to store the PocketBase ID

  @override
  @Property()
  String? customer; // Add this field

  DeliveryUpdateModel({
    super.id, // Make id required
    super.collectionId,
    super.collectionName,
    super.title,
    super.subtitle,
    super.time,
    super.created,
    super.updated,
    this.customer,
    super.isAssigned,
    super.assignedTo,
    super.image,
    super.remarks,
  }) : pocketbaseId = id ?? '';

  factory DeliveryUpdateModel.fromJson(DataMap json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('📅 Date parse fallback to current time');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    bool parseBoolean(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return DeliveryUpdateModel(
      id: json['id'],
      collectionId: json['collectionId']?.toString() ?? '',
      collectionName: json['collectionName']?.toString() ?? 'delivery_update',
      title: json['title']?.toString() ?? 'Pending',
      subtitle: json['subtitle']?.toString() ?? 'Waiting to Accept the Trip',
      time: parseDate(json['time']),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
      customer: json['customer']?.toString(),
      isAssigned: parseBoolean(json['isAssigned']),
      assignedTo: json['assignedTo']?.toString(),
      remarks: json['remarks']?.toString(),
      image: json['image']?.toString(), // Added image parsing
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'created': created,
      'updated': updated,
      'customer': customer,
      'isAssigned': isAssigned,
      'assignedTo': assignedTo,
      'remarks': remarks,
      'image': image,
    };
  }

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
      customer: customerId ?? '',
      isAssigned: false,
      assignedTo: null,
      image: null,
      remarks: ''
    );
  }

  DeliveryUpdateModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? title,
    String? subtitle,
    DateTime? time,
    DateTime? created,
    DateTime? updated,
    String? customer,
    bool? isAssigned,
    String? assignedTo,
    String? image,
    String? remarks,
  }) {
    return DeliveryUpdateModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      customer: customer ?? this.customer,
      isAssigned: isAssigned ?? this.isAssigned,
      assignedTo: assignedTo ?? this.assignedTo,
      remarks: remarks ?? this.remarks,
      image: image ?? this.image,
    );
  }
}
