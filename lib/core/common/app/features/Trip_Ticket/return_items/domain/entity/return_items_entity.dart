import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../../enums/product_return_reason.dart';
import '../../../delivery_data/data/model/delivery_data_model.dart';
import '../../../../delivery_data/invoice_data/data/model/invoice_data_model.dart';
import '../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart' show InvoiceItemsModel;
import '../../../trip/data/models/trip_models.dart';

@Entity()
class ReturnItemsEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final ToOne<DeliveryDataModel> deliveryData = ToOne<DeliveryDataModel>();
  final ToOne<InvoiceItemsModel> invoiceItem = ToOne<InvoiceItemsModel>();
  final ToOne<InvoiceDataModel> invoiceData = ToOne<InvoiceDataModel>();

  // Return item specific fields
  final String? refId;
  final int? quantity;
  final String? uom;
  final ProductReturnReason? reason;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  ReturnItemsEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    TripModel? tripData,
    DeliveryDataModel? deliveryDataModel,
    InvoiceItemsModel? invoiceItemData,
    InvoiceDataModel? invoiceDataModel,
    this.refId,
    this.quantity,
    this.uom,
    this.reason,
    this.created,
    this.updated,
  }) {
    if (tripData != null) trip.target = tripData;
    if (deliveryDataModel != null) deliveryData.target = deliveryDataModel;
    if (invoiceItemData != null) invoiceItem.target = invoiceItemData;
    if (invoiceDataModel != null) invoiceData.target = invoiceDataModel;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    trip.target?.id,
    deliveryData.target?.id,
    invoiceItem.target?.id,
    invoiceData.target?.id,
    refId,
    quantity,
    uom,
    reason,
    created,
    updated,
  ];
}
