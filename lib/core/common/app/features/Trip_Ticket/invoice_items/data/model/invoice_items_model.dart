import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:pocketbase/pocketbase.dart';

class InvoiceItemsModel extends InvoiceItemsEntity {
  int objectBoxId = 0;
  String pocketbaseId;

  InvoiceItemsModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.name,
    super.brand,
    super.refId,
    super.uom,
    super.quantity,
    super.totalBaseQuantity,
    super.uomPrice,
    super.totalAmount,
    super.invoiceData,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '';

  factory InvoiceItemsModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Handle expanded data for invoice data relation
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
            'name': invoiceData.data['name'] ?? '',
            'refId': invoiceData.data['refId'] ?? '',
            ...invoiceData.data,
            'expand': invoiceData.expand,
          });
        } else if (invoiceData is Map) {
          invoiceDataModel = InvoiceDataModel.fromJson(invoiceData as DataMap);
        }
      }
    }

    return InvoiceItemsModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      name: json['name']?.toString(),
      brand: json['brand']?.toString(),
      refId: json['refId']?.toString(),
      uom: json['uom']?.toString(),
      quantity:
          json['quantity'] != null
              ? double.tryParse(json['quantity'].toString())
              : null,
      totalBaseQuantity:
          json['totalBaseQuantity'] != null
              ? double.tryParse(json['totalBaseQuantity'].toString())
              : null,
      uomPrice:
          json['uomPrice'] != null
              ? double.tryParse(json['uomPrice'].toString())
              : null,
      totalAmount:
          json['totalAmount'] != null
              ? double.tryParse(json['totalAmount'].toString())
              : null,
      invoiceData: invoiceDataModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name ?? '',
      'brand': brand ?? '',
      'refId': refId ?? '',
      'uom': uom ?? '',
      'quantity': quantity?.toString() ?? '',
      'totalBaseQuantity': totalBaseQuantity?.toString() ?? '',
      'uomPrice': uomPrice?.toString() ?? '',
      'totalAmount': totalAmount?.toString() ?? '',
      'invoiceData': invoiceData?.id ?? '',
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  InvoiceItemsModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? name,
    String? brand,
    String? refId,
    String? uom,
    double? quantity,
    double? totalBaseQuantity,
    double? uomPrice,
    double? totalAmount,
    InvoiceDataModel? invoiceData,
    DateTime? created,
    DateTime? updated,
  }) {
    return InvoiceItemsModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      refId: refId ?? this.refId,
      uom: uom ?? this.uom,
      quantity: quantity ?? this.quantity,
      totalBaseQuantity: totalBaseQuantity ?? this.totalBaseQuantity,
      uomPrice: uomPrice ?? this.uomPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      invoiceData: invoiceData ?? this.invoiceData,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItemsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
