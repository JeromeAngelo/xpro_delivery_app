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

   /// Create from a PocketBase RecordModel
  factory NotificationModel.fromRecord(RecordModel record) {
    // RecordModel.toJson() returns a Map<String, dynamic> which matches DataMap
    return NotificationModel.fromJson(record.toJson());
  }

  factory NotificationModel.fromJson(DataMap json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;

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
          deliveryDataModel = DeliveryDataModel.fromJson(
            deliveryData as DataMap,
          );
        }
      }
    } else if (json['delivery'] != null) {
      deliveryDataModel = DeliveryDataModel.fromJson(
        json['delivery'] as DataMap,
      );
    }

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
          deliveryUpdateModel = DeliveryUpdateModel.fromJson(
            deliveryUpdateData as DataMap,
          );
        }
      }
    } else if (json['status'] != null) {
      deliveryUpdateModel = DeliveryUpdateModel.fromJson(
        json['status'] as DataMap,
      );
    }

    // Process trip relation
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
        }
      }
    } else if (json['trip'] != null) {
      // If not expanded, just store the ID
      tripModel = TripModel(id: json['trip'].toString());
    }

    NotificationTypeEnum parseType(String? typeStr) {
      if (typeStr != null) return NotificationTypeEnum.none;

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
      id: json['id'].toString(),
      delivery: deliveryDataModel,
      status: deliveryUpdateModel,
      trip: tripModel,
      createdAt: parseDate(json['created']),
      type: type,
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
