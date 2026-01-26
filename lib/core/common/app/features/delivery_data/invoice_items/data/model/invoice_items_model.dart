import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class InvoiceItemsModel extends InvoiceItemsEntity {
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
  String? name;

  @override
  @Property()
  String? brand;

  @override
  @Property()
  String? refId;

  @override
  @Property()
  String? uom;

  @override
  @Property()
  double? quantity;

  @override
  @Property()
  double? totalBaseQuantity;

  @override
  @Property()
  double? uomPrice;

  @override
  @Property()
  double? totalAmount;

  @Property()
  String pocketbaseId;

  @Property()
  String? invoiceDataId;

  /// --- Relation ---
  @override
  final invoiceData = ToOne<InvoiceDataModel>();

  @override
  @Property()
  DateTime? created;

  @override
  @Property()
  DateTime? updated;

  InvoiceItemsModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.name,
    this.brand,
    this.refId,
    this.uom,
    this.quantity,
    this.totalBaseQuantity,
    this.uomPrice,
    this.totalAmount,
    InvoiceDataModel? invoiceDataModel,
    this.created,
    this.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '' {
    if (invoiceDataModel != null) {
      invoiceData.target = invoiceDataModel;
      invoiceDataId = invoiceDataModel.id;
    }
  }

  /// --- From JSON ---
  factory InvoiceItemsModel.fromJson(dynamic json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final expanded = json['expand'] as Map<String, dynamic>?;
    InvoiceDataModel? invoiceDataModel;

    if (expanded != null && expanded.containsKey('invoiceData')) {
      final data = expanded['invoiceData'];
      if (data != null) {
        if (data is Map) {
          invoiceDataModel = InvoiceDataModel.fromJson(data as DataMap);
        }
      }
    } else if (json['invoiceData'] != null) {
      invoiceDataModel = InvoiceDataModel(id: json['invoiceData'].toString());
    }

    return InvoiceItemsModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      name: json['name']?.toString(),
      brand: json['brand']?.toString(),
      refId: json['refId']?.toString(),
      uom: json['uom']?.toString(),
      quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null,
      totalBaseQuantity: json['totalBaseQuantity'] != null ? double.tryParse(json['totalBaseQuantity'].toString()) : null,
      uomPrice: json['uomPrice'] != null ? double.tryParse(json['uomPrice'].toString()) : null,
      totalAmount: json['totalAmount'] != null ? double.tryParse(json['totalAmount'].toString()) : null,
      invoiceDataModel: invoiceDataModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  /// --- To JSON ---
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
      'invoiceData': invoiceData.target?.id ?? '',
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  /// --- Copy With ---
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
    InvoiceDataModel? invoiceDataModel,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = InvoiceItemsModel(
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
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );

    if (invoiceDataModel != null) {
      model.invoiceData.target = invoiceDataModel;
    } else if (invoiceData.target != null) {
      model.invoiceData.target = invoiceData.target;
    }

    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItemsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InvoiceItemsModel(id: $id, name: $name, refId: $refId, invoiceData: ${invoiceData.target?.id})';
  }
}
