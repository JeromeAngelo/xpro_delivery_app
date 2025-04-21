import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';
@Entity()
class UndeliverableCustomerEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? deliveryNumber;
  String? storeName;
  String? ownerName;
  List<String>? contactNumber;
  String? address;
  String? municipality;
  String? province;
  String? modeOfPayment;
  UndeliverableReason? reason;
  DateTime? time;
  DateTime? created;
  DateTime? updated;
  String? customerImage;

  @Property()
  final List<InvoiceModel> invoicesList;
  final ToMany<InvoiceModel> invoices = ToMany<InvoiceModel>();

  @Property()
  final CustomerModel? customer;
  final ToOne<CustomerModel> customerRef = ToOne<CustomerModel>();

  @Property()
  final TripModel? trip;
  final ToOne<TripModel> tripRef = ToOne<TripModel>();

  UndeliverableCustomerEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.deliveryNumber,
    this.storeName,
    this.ownerName,
    this.contactNumber,
    this.address,
    this.municipality,
    this.province,
    this.modeOfPayment,
    List<InvoiceModel>? invoicesList,
    this.customer,
    this.reason,
    this.time,
    this.created,
    this.updated,
    this.customerImage,
    this.trip,
  }) : invoicesList = invoicesList ?? [] {
    if (invoicesList != null) invoices.addAll(invoicesList);
    if (customer != null) customerRef.target = customer;
    if (trip != null) tripRef.target = trip;
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        deliveryNumber,
        storeName,
        ownerName,
        contactNumber,
        address,
        municipality,
        province,
        modeOfPayment,
        invoicesList,
        invoices,
        customer,
        customerRef,
        trip,
        tripRef,
        reason,
        time,
        created,
        updated,
        customerImage,
      ];
}
