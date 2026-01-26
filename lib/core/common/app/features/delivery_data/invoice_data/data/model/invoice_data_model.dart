import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class InvoiceDataModel extends InvoiceDataEntity {
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
  String? refId;

  @override
  @Property()
  String? name;

  @override
  @Property()
  DateTime? documentDate;

  @override
  @Property()
  double? totalAmount;

  @override
  @Property()
  double? volume;

  @override
  @Property()
  double? weight;

  @override
  @Property()
  DateTime? created;

  @override
  @Property()
  DateTime? updated;

  /// Pocketbase ID
  @Property()
  String pocketbaseId;

  /// --- Relation ---
  @override
  final customer = ToOne<CustomerDataModel>();

  InvoiceDataModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.refId,
    this.name,
    this.documentDate,
    this.totalAmount,
    this.volume,
    this.weight,
    CustomerDataModel? customerData,
    this.created,
    this.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '' {
    if (customerData != null) {
      customer.target = customerData;
    }
  }

  /// --- From JSON ---
  factory InvoiceDataModel.fromJson(dynamic json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final expanded = json['expand'] as Map<String, dynamic>?;
    CustomerDataModel? customerModel;

    if (expanded != null && expanded['customer'] != null) {
      final data = expanded['customer'];
      if (data is Map<String, dynamic>) {
        customerModel = CustomerDataModel.fromJson(data);
      } else if (data is CustomerDataModel) {
        customerModel = data;
      }
    } else if (json['customer'] != null) {
      customerModel = CustomerDataModel(id: json['customer'].toString());
    }

    return InvoiceDataModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      refId: json['refId']?.toString(),
      name: json['name']?.toString(),
      documentDate: parseDate(json['documentDate']),
      totalAmount: json['totalAmount'] != null ? double.tryParse(json['totalAmount'].toString()) : null,
      volume: json['volume'] != null ? double.tryParse(json['volume'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      customerData: customerModel,
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
      'refId': refId ?? '',
      'name': name ?? '',
      'documentDate': documentDate?.toIso8601String() ?? '',
      'totalAmount': totalAmount?.toString() ?? '',
      'volume': volume?.toString() ?? '',
      'weight': weight?.toString() ?? '',
      'customer': customer.target?.id ?? '',
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  /// --- Copy With ---
  InvoiceDataModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? refId,
    String? name,
    DateTime? documentDate,
    double? totalAmount,
    double? volume,
    double? weight,
    CustomerDataModel? customerData,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = InvoiceDataModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      refId: refId ?? this.refId,
      name: name ?? this.name,
      documentDate: documentDate ?? this.documentDate,
      totalAmount: totalAmount ?? this.totalAmount,
      volume: volume ?? this.volume,
      weight: weight ?? this.weight,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );

    if (customerData != null) {
      model.customer.target = customerData;
    } else if (customer.target != null) {
      model.customer.target = customer.target;
    }

    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InvoiceDataModel(id: $id, refId: $refId, name: $name, customer: ${customer.target?.id})';
  }
}
