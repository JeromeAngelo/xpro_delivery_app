import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/enums/notification_type_enum.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import '../../../Trip_Ticket/trip/data/models/trip_models.dart';
import '../../domain/entity/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    super.id,
    super.delivery,
    super.status,
    super.trip,
    super.createdAt,
    super.type,
  });
factory NotificationModel.fromJson(DataMap json) {
  DateTime? parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  final expandedData = json['expand'] as Map<String, dynamic>?;

  // -----------------------------
  // ✅ delivery relation (safe)
  // -----------------------------
  DeliveryDataModel? deliveryDataModel;
  if (expandedData != null && expandedData.containsKey('delivery')) {
    final deliveryData = expandedData['delivery'];
    if (deliveryData != null) {
      if (deliveryData is RecordModel) {
        deliveryDataModel = DeliveryDataModel.fromJson({
          'id': deliveryData.id,
          'collectionId': deliveryData.collectionId,
          'collectionName': deliveryData.collectionName,
          ...deliveryData.data,
          'expand': deliveryData.expand,
        });
      } else if (deliveryData is Map) {
        deliveryDataModel = DeliveryDataModel.fromJson(deliveryData as DataMap);
      } else if (deliveryData is String) {
        // fallback if expand gives only id
        deliveryDataModel = DeliveryDataModel(id: deliveryData);
      }
    }
  } else if (json['delivery'] != null) {
    final d = json['delivery'];

    // ✅ Handle string ID vs map
    if (d is String) {
      deliveryDataModel = DeliveryDataModel(id: d);
    } else if (d is Map) {
      deliveryDataModel = DeliveryDataModel.fromJson(d as DataMap);
    } else {
      // last resort
      deliveryDataModel = DeliveryDataModel(id: d.toString());
    }
  }

  // -----------------------------
  // ✅ status relation (safe)
  // -----------------------------
  DeliveryUpdateModel? deliveryUpdateModel;
  if (expandedData != null && expandedData.containsKey('status')) {
    final deliveryUpdateData = expandedData['status'];
    if (deliveryUpdateData != null) {
      if (deliveryUpdateData is RecordModel) {
        deliveryUpdateModel = DeliveryUpdateModel.fromJson({
          'id': deliveryUpdateData.id,
          'collectionId': deliveryUpdateData.collectionId,
          'collectionName': deliveryUpdateData.collectionName,
          ...deliveryUpdateData.data,
          'expand': deliveryUpdateData.expand,
        });
      } else if (deliveryUpdateData is Map) {
        deliveryUpdateModel =
            DeliveryUpdateModel.fromJson(deliveryUpdateData as DataMap);
      } else if (deliveryUpdateData is String) {
        deliveryUpdateModel = DeliveryUpdateModel(id: deliveryUpdateData);
      }
    }
  } else if (json['status'] != null) {
    final s = json['status'];

    // ✅ Handle string ID vs map
    if (s is String) {
      deliveryUpdateModel = DeliveryUpdateModel(id: s);
    } else if (s is Map) {
      deliveryUpdateModel = DeliveryUpdateModel.fromJson(s as DataMap);
    } else {
      deliveryUpdateModel = DeliveryUpdateModel(id: s.toString());
    }
  }

  // -----------------------------
  // ✅ trip relation (already safe)
  // -----------------------------
  TripModel? tripModel;
  if (expandedData != null && expandedData.containsKey('trip')) {
    final tripData = expandedData['trip'];
    if (tripData != null) {
      if (tripData is RecordModel) {
        tripModel = TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
          'expand': tripData.expand,
        });
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as DataMap);
      } else if (tripData is String) {
        tripModel = TripModel(id: tripData);
      }
    }
  } else if (json['trip'] != null) {
    tripModel = TripModel(id: json['trip'].toString());
  }

  // -----------------------------
  // ✅ Fix parseType bug
  // -----------------------------
  NotificationTypeEnum parseType(String? typeStr) {
    if (typeStr == null) return NotificationTypeEnum.none;

    switch (typeStr) {
      case 'tripUpdate':
        return NotificationTypeEnum.tripUpdate;
      case 'deliveryUpdate':
        return NotificationTypeEnum.deliveryUpdate;
      default:
        return NotificationTypeEnum.none;
    }
  }

  final type = parseType(json['type']?.toString());

  return NotificationModel(
    id: json['id']?.toString(),
    delivery: deliveryDataModel,
    status: deliveryUpdateModel,
    trip: tripModel,
    createdAt: parseDate(json['created']),
    type: type,
  );
}


    /// Empty / placeholder notification
  factory NotificationModel.empty() {
    return NotificationModel(
      id: '',
      delivery: null,
      status: null,
      trip: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      type: NotificationTypeEnum.none,
    );
  }


  DataMap toJson() {
    return {
      'id': id,
      'delivery': delivery,
      'status': status,
      'trip': trip,
      'created': createdAt?.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  NotificationModel copyWith({
    String? id,
    DeliveryDataModel? delivery,
    DeliveryUpdateModel? status,
    TripModel? trip,
    DateTime? createdAt,
    NotificationTypeEnum? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      delivery: delivery ?? this.delivery,
      status: status ?? this.status,
      trip: trip ?? this.trip,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}
