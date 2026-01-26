import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';

@Entity()
class CollectionEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
 String? collectionId;
  String? collectionName;

  // Relations
  final ToOne<DeliveryDataModel> deliveryData = ToOne<DeliveryDataModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final ToOne<CustomerDataModel> customer = ToOne<CustomerDataModel>();
  final ToOne<InvoiceDataModel> invoice = ToOne<InvoiceDataModel>();
  final ToMany<InvoiceDataModel> invoices = ToMany<InvoiceDataModel>();

  final double? totalAmount;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  CollectionEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    DeliveryDataModel? deliveryDataModel,
    TripModel? tripData,
    CustomerDataModel? customerData,
    InvoiceDataModel? invoiceData,
    List<InvoiceDataModel>? invoicesList,
    this.totalAmount,
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
    totalAmount,
    created,
    updated,
  ];
}
