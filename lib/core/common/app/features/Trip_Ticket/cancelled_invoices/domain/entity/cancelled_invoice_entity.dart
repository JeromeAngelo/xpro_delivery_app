import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

@Entity()
class CancelledInvoiceEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<DeliveryDataModel> deliveryData = ToOne<DeliveryDataModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final ToOne<CustomerDataModel> customer = ToOne<CustomerDataModel>();
  final ToOne<InvoiceDataModel> invoice = ToOne<InvoiceDataModel>();
  final ToMany<InvoiceDataModel> invoices = ToMany<InvoiceDataModel>();

  UndeliverableReason? reason;
  String? image;

  // Standard fields
  final DateTime? created;
  DateTime? updated;

  CancelledInvoiceEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    DeliveryDataModel? deliveryDataModel,
    TripModel? tripData,
    CustomerDataModel? customerData,
    InvoiceDataModel? invoiceData,
    List<InvoiceDataModel>? invoicesList,
    this.reason,
    this.image,
    this.created,
    this.updated,
  }) {
    if (deliveryDataModel != null) deliveryData.target = deliveryDataModel;
    if (tripData != null) trip.target = tripData;
    if (customerData != null) customer.target = customerData;
    if (invoiceData != null) invoice.target = invoiceData;
    if (invoicesList != null) invoices.addAll(invoicesList);
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    deliveryData.target?.id,
    trip.target?.id,
    customer.target?.id,
    invoice.target?.id,
    invoices,
    reason,
    image,
    created,
    updated,
  ];
}
