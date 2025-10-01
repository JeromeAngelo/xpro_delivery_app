import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';

@Entity()
class DeliveryReceiptItemsEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<DeliveryReceiptModel> deliveryReceipt = ToOne<DeliveryReceiptModel>();
  final ToMany<InvoiceItemsModel> invoiceItems = ToMany<InvoiceItemsModel>();

  final String? status;
  final double? totalAmount;
  final String? customerImage;
  final String? receiptFile;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  DeliveryReceiptItemsEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    DeliveryReceiptModel? deliveryReceiptData,
    List<InvoiceItemsModel>? invoiceItemsList,
    this.status,
    this.totalAmount,
    this.customerImage,
    this.receiptFile,
    this.created,
    this.updated,
  }) {
    if (deliveryReceiptData != null) deliveryReceipt.target = deliveryReceiptData;
    if (invoiceItemsList != null) {
      invoiceItems.addAll(invoiceItemsList);
    }
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    deliveryReceipt.target?.id,
    invoiceItems.map((item) => item.id).toList(),
    status,
    totalAmount,
    customerImage,
    receiptFile,
    created,
    updated,
  ];
}
