import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';

import '../../../../../../../enums/invoice_status.dart';
import '../../../trip/data/models/trip_models.dart';

@Entity()
class DeliveryDataEntity extends Equatable {
  @Id()
  int dbId = 0;

 String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<CustomerDataModel> customer = ToOne<CustomerDataModel>();
  final ToOne<InvoiceDataModel> invoice = ToOne<InvoiceDataModel>();
  final ToMany<InvoiceDataModel> invoices = ToMany<InvoiceDataModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final ToMany<DeliveryUpdateEntity> deliveryUpdates =
      ToMany<DeliveryUpdateEntity>();
  final ToMany<InvoiceItemsModel> invoiceItems = ToMany<InvoiceItemsModel>();

  final String? paymentMode;
  late final String? deliveryNumber;
 String? totalDeliveryTime;
 InvoiceStatus? invoiceStatus;

  // New additional fields
  final String? storeName;
  final String? ownerName;
  final String? contactNumber;
  final String? barangay;
  final String? municipality;
  final String? province;
  final String? refID;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;
  final bool? hasTrip;

  //payment selection
  final ModeOfPayment? paymentSelection;

  DeliveryDataEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    CustomerDataModel? customerData,
    InvoiceDataModel? invoiceData,
    List<InvoiceDataModel>? invoicesList,
    TripModel? tripData,
    List<DeliveryUpdateModel>? deliveryUpdatesList,
    List<InvoiceItemsModel>? invoiceItemsList,
    this.deliveryNumber,
    this.paymentSelection,
    this.totalDeliveryTime,
    this.paymentMode,
    this.invoiceStatus,
    this.storeName,
    this.ownerName,
    this.contactNumber,
    this.barangay,
    this.municipality,
    this.province,
    this.refID,
    this.created,
    this.updated,
    this.hasTrip,
  }) {
    if (customerData != null) customer.target = customerData;
    if (invoiceData != null) invoice.target = invoiceData;
    if (invoicesList != null) invoices.addAll(invoicesList);
    if (tripData != null) trip.target = tripData;
    if (deliveryUpdatesList != null) {
      deliveryUpdates.addAll(deliveryUpdatesList);
    }
    if (invoiceItemsList != null) {
      invoiceItems.addAll(invoiceItemsList);
    }
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    customer.target?.id,
    invoice.target?.id,
    invoices,
    trip.target?.id,
    paymentSelection,
    totalDeliveryTime,
    deliveryNumber,
    invoiceStatus,
    deliveryUpdates,
    invoiceItems,
    paymentMode,
    storeName,
    ownerName,
    contactNumber,
    barangay,
    municipality,
    province,
    refID,
    hasTrip,
    created,
    updated,
  ];
}
