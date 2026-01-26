import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/entity/return_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class ReturnItemsModel extends ReturnItemsEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  ReturnItemsModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    TripModel? trip,
    DeliveryDataModel? deliveryData,
    InvoiceItemsModel? invoiceItem,
    InvoiceDataModel? invoiceData,
    super.refId,
    super.quantity,
    super.uom,
    super.reason,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '',
       super(
         tripData: trip,
         deliveryDataModel: deliveryData,
         invoiceItemData: invoiceItem,
         invoiceDataModel: invoiceData,
       );

  factory ReturnItemsModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse return reason enum
    ProductReturnReason? parseReturnReason(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        final enumValue = value.toString().toLowerCase();
        switch (enumValue) {
          case 'damaged':
            return ProductReturnReason.damaged;
          case 'dented':
            return ProductReturnReason.dented;
          case 'expired':
            return ProductReturnReason.expired;
          case 'wrongProduct':
            return ProductReturnReason.wrongProduct;

          case 'wrongQuantity':
            return ProductReturnReason.wrongQuantity;
          case 'other':
            return ProductReturnReason.other;
          case 'none':
            return ProductReturnReason.none;
          default:
            debugPrint('⚠️ Unknown return reason: $enumValue');
            return null;
        }
      } catch (e) {
        debugPrint('❌ Error parsing return reason: $e');
        return null;
      }
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;

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

    // Process delivery data relation
    DeliveryDataModel? deliveryDataModel;
    if (expandedData != null && expandedData.containsKey('deliveryData')) {
      final deliveryData = expandedData['deliveryData'];
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
    } else if (json['deliveryData'] != null) {
      // If not expanded, just store the ID
      deliveryDataModel = DeliveryDataModel(
        id: json['deliveryData'].toString(),
      );
    }

    // Process invoice item relation
    InvoiceItemsModel? invoiceItemModel;
    if (expandedData != null && expandedData.containsKey('invoiceItem')) {
      final invoiceItemData = expandedData['invoiceItem'];
      if (invoiceItemData != null) {
        if (invoiceItemData is RecordModel) {
          invoiceItemModel = InvoiceItemsModel.fromJson({
            'id': invoiceItemData.id,
            'collectionId': invoiceItemData.collectionId,
            'collectionName': invoiceItemData.collectionName,
            ...invoiceItemData.data,
            'expand': invoiceItemData.expand,
          });
        } else if (invoiceItemData is Map) {
          invoiceItemModel = InvoiceItemsModel.fromJson(
            invoiceItemData as DataMap,
          );
        }
      }
    } else if (json['invoiceItem'] != null) {
      // If not expanded, just store the ID
      invoiceItemModel = InvoiceItemsModel(id: json['invoiceItem'].toString());
    }

    // Process invoice data relation
    InvoiceDataModel? invoiceDataModel;
    if (expandedData != null && expandedData.containsKey('invoiceData')) {
      final invoiceData = expandedData['invoiceData'];
      if (invoiceData != null) {
        if (invoiceData is RecordModel) {
          invoiceDataModel = InvoiceDataModel.fromJson({
            'id': invoiceData.id,
            'collectionId': invoiceData.collectionId,
            'collectionName': invoiceData.collectionName,
            ...invoiceData.data,
            'expand': invoiceData.expand,
          });
        } else if (invoiceData is Map) {
          invoiceDataModel = InvoiceDataModel.fromJson(invoiceData as DataMap);
        }
      }
    } else if (json['invoiceData'] != null) {
      // If not expanded, just store the ID
      invoiceDataModel = InvoiceDataModel(id: json['invoiceData'].toString());
    }

    return ReturnItemsModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      refId: json['refId']?.toString(),
      quantity: json['quantity'] as int?,
      uom: json['uom']?.toString(),
      reason: parseReturnReason(json['reason']),
      trip: tripModel,
      deliveryData: deliveryDataModel,
      invoiceItem: invoiceItemModel,
      invoiceData: invoiceDataModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    // Convert enum to string for JSON serialization
    String? reasonString;
    if (reason != null) {
      switch (reason!) {
        case ProductReturnReason.damaged:
          reasonString = 'damaged';
          break;
        case ProductReturnReason.dented:
          reasonString = 'dented';
          break;
        case ProductReturnReason.wrongProduct:
          reasonString = 'wrongProduct';
          break;
        case ProductReturnReason.wrongQuantity:
          reasonString = 'wrongQuantity';
          break;
        case ProductReturnReason.expired:
          reasonString = 'expired';
          break;
        case ProductReturnReason.other:
          reasonString = 'other';
          break;
        case ProductReturnReason.none:
          reasonString = 'none';
          break;
      }
    }

    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'refId': refId,
      'quantity': quantity,
      'uom': uom,
      'reason': reasonString,
      'trip': trip.target?.id,
      'deliveryData': deliveryData.target?.id,
      'invoiceItem': invoiceItem.target?.id,
      'invoiceData': invoiceData.target?.id,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  ReturnItemsModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? refId,
    int? quantity,
    String? uom,
    ProductReturnReason? reason,
    TripModel? trip,
    DeliveryDataModel? deliveryData,
    InvoiceItemsModel? invoiceItem,
    InvoiceDataModel? invoiceData,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = ReturnItemsModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      refId: refId ?? this.refId,
      quantity: quantity ?? this.quantity,
      uom: uom ?? this.uom,
      reason: reason ?? this.reason,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );

    // Handle relations
    if (trip != null) {
      model.trip.target = trip;
    } else if (this.trip.target != null) {
      model.trip.target = this.trip.target;
    }

    if (deliveryData != null) {
      model.deliveryData.target = deliveryData;
    } else if (this.deliveryData.target != null) {
      model.deliveryData.target = this.deliveryData.target;
    }

    if (invoiceItem != null) {
      model.invoiceItem.target = invoiceItem;
    } else if (this.invoiceItem.target != null) {
      model.invoiceItem.target = this.invoiceItem.target;
    }

    if (invoiceData != null) {
      model.invoiceData.target = invoiceData;
    } else if (this.invoiceData.target != null) {
      model.invoiceData.target = this.invoiceData.target;
    }

    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReturnItemsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReturnItemsModel(id: $id, refId: $refId, quantity: $quantity, uom: $uom, reason: $reason, trip: ${trip.target?.id}, deliveryData: ${deliveryData.target?.id}, invoiceItem: ${invoiceItem.target?.id}, invoiceData: ${invoiceData.target?.id})';
  }
}
