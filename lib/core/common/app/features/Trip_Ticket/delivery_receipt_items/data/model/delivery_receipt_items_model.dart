import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt_items/domain/entity/delivery_receipt_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class DeliveryReceiptItemsModel extends DeliveryReceiptItemsEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String? deliveryReceiptId;

  DeliveryReceiptItemsModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    DeliveryReceiptModel? deliveryReceipt,
    List<InvoiceItemsModel>? invoiceItems,
    super.status,
    super.totalAmount,
    super.customerImage,
    super.receiptFile,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    deliveryReceiptId = deliveryReceipt?.id,
    super(
      deliveryReceiptData: deliveryReceipt,
      invoiceItemsList: invoiceItems,
    );

  factory DeliveryReceiptItemsModel.fromJson(DataMap json) {
    // Add safe date parsing
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
    
    // Process deliveryReceipt relation
    DeliveryReceiptModel? deliveryReceiptModel;
    if (expandedData != null && expandedData.containsKey('deliveryReceipt')) {
      final deliveryReceiptData = expandedData['deliveryReceipt'];
      if (deliveryReceiptData != null) {
        if (deliveryReceiptData is RecordModel) {
          deliveryReceiptModel = DeliveryReceiptModel.fromJson({
            'id': deliveryReceiptData.id,
            'collectionId': deliveryReceiptData.collectionId,
            'collectionName': deliveryReceiptData.collectionName,
            ...deliveryReceiptData.data,
            'expand': deliveryReceiptData.expand,
          });
        } else if (deliveryReceiptData is Map) {
          deliveryReceiptModel = DeliveryReceiptModel.fromJson(deliveryReceiptData as DataMap);
        }
      }
    } else if (json['deliveryReceipt'] != null) {
      // If not expanded, just store the ID
      deliveryReceiptModel = DeliveryReceiptModel(id: json['deliveryReceipt'].toString());
    }
    
    // Process invoiceItems relation (multiple)
    List<InvoiceItemsModel> invoiceItemsList = [];
    if (expandedData != null && expandedData.containsKey('invoiceItems')) {
      final invoiceItemsData = expandedData['invoiceItems'];
      if (invoiceItemsData != null && invoiceItemsData is List) {
        invoiceItemsList = invoiceItemsData.map((item) {
          if (item is RecordModel) {
            return InvoiceItemsModel.fromJson({
              'id': item.id,
              'collectionId': item.collectionId,
              'collectionName': item.collectionName,
              ...item.data,
              'expand': item.expand,
            });
          } else if (item is Map) {
            return InvoiceItemsModel.fromJson(item as DataMap);
          }
          // If it's just an ID string, create a minimal model
          return InvoiceItemsModel(id: item.toString());
        }).toList();
      }
    } else if (json['invoiceItems'] != null && json['invoiceItems'] is List) {
      // If not expanded, just store the IDs
      invoiceItemsList = (json['invoiceItems'] as List)
          .map((id) => InvoiceItemsModel(id: id.toString()))
          .toList();
    }

    return DeliveryReceiptItemsModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      status: json['status']?.toString(),
      totalAmount: json['totalAmount'] != null ? double.tryParse(json['totalAmount'].toString()) : null,
      customerImage: json['customerImage']?.toString(),
      receiptFile: json['receiptFile']?.toString(),
      deliveryReceipt: deliveryReceiptModel,
      invoiceItems: invoiceItemsList,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'status': status,
      'totalAmount': totalAmount?.toString(),
      'customerImage': customerImage,
      'receiptFile': receiptFile,
      'deliveryReceipt': deliveryReceipt.target?.id,
      'invoiceItems': invoiceItems.map((item) => item.id).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  DeliveryReceiptItemsModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryReceiptModel? deliveryReceipt,
    List<InvoiceItemsModel>? invoiceItems,
    String? status,
    double? totalAmount,
    String? customerImage,
    String? receiptFile,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = DeliveryReceiptItemsModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      customerImage: customerImage ?? this.customerImage,
      receiptFile: receiptFile ?? this.receiptFile,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
    
    // Handle deliveryReceipt relation
    if (deliveryReceipt != null) {
      model.deliveryReceipt.target = deliveryReceipt;
    } else if (this.deliveryReceipt.target != null) {
      model.deliveryReceipt.target = this.deliveryReceipt.target;
    }
    
    // Handle invoiceItems relation
    if (invoiceItems != null) {
      model.invoiceItems.clear();
      model.invoiceItems.addAll(invoiceItems);
    } else if (this.invoiceItems.isNotEmpty) {
      model.invoiceItems.clear();
      model.invoiceItems.addAll(this.invoiceItems);
    }
    
    return model;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryReceiptItemsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryReceiptItemsModel(id: $id, deliveryReceipt: ${deliveryReceipt.target?.id}, invoiceItems: ${invoiceItems.length}, status: $status, totalAmount: $totalAmount)';
  }
}
