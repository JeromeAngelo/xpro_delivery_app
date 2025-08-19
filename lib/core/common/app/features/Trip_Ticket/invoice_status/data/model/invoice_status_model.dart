import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/domain/entity/invoice_status_entity.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class InvoiceStatusModel extends InvoiceStatusEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  InvoiceStatusModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    InvoiceDataModel? invoiceData,
    super.tripStatus,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    super(invoiceDataModel: invoiceData);

  factory InvoiceStatusModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse tripStatus enum
    InvoiceStatus? parseTripStatus(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        final enumValue = value.toString().toLowerCase();
        switch (enumValue) {
          case 'none':
          case 'pending':
          case '':
            return InvoiceStatus.none;
          case 'truck':
          case 'in_truck':
          case 'intruck':
            return InvoiceStatus.truck;
          case 'unloading':
            return InvoiceStatus.unloading;
          case 'unloaded':
            return InvoiceStatus.unloaded;
          case 'completed':
          case 'complete':
          case 'delivered':
            return InvoiceStatus.delivered;
          case 'cancelled':
          case 'canceled':
            return InvoiceStatus.cancelled;
          default:
            debugPrint('⚠️ Unknown trip status: $enumValue');
            return InvoiceStatus.none;
        }
      } catch (e) {
        debugPrint('❌ Error parsing trip status: $e');
        return null;
      }
    }

    // Handle expanded data for invoiceData relation
    final expandedData = json['expand'] as Map<String, dynamic>?;
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

    return InvoiceStatusModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      invoiceData: invoiceDataModel,
      tripStatus: parseTripStatus(json['tripStatus']),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'invoiceData': invoiceData.target?.id,
      'tripStatus': tripStatus?.name,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  InvoiceStatusModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    InvoiceDataModel? invoiceData,
    InvoiceStatus? tripStatus,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = InvoiceStatusModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      tripStatus: tripStatus ?? this.tripStatus,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
    
    // Handle invoiceData relation
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
    return other is InvoiceStatusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InvoiceStatusModel(id: $id, invoiceData: ${invoiceData.target?.id}, tripStatus: $tripStatus, created: $created, updated: $updated)';
  }
}
