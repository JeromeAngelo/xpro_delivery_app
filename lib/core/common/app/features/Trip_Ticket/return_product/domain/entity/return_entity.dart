import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';

import '../../../trip/data/models/trip_models.dart';
@Entity()
class ReturnEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? productName;
  final String? productDescription;
  final ProductReturnReason? reason;
  final DateTime? returnDate;
  
  @Property()
  final int? productQuantityCase;
  @Property()
  final int? productQuantityPcs;
  @Property()
  final int? productQuantityPack;
  @Property()
  final int? productQuantityBox;
  
  @Property()
  final bool? isCase;
  @Property()
  final bool? isPcs;
  @Property()
  final bool? isBox;
  @Property()
  final bool? isPack;

  @Property()
  final InvoiceModel? invoice;
  final ToOne<InvoiceModel> invoiceRef = ToOne<InvoiceModel>();

  @Property()
  final CustomerModel? customer;
  final ToOne<CustomerModel> customerRef = ToOne<CustomerModel>();

  @Property()
  final TripModel? trip;
  final ToOne<TripModel> tripRef = ToOne<TripModel>();

  ReturnEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.productName,
    this.productDescription,
    this.reason,
    this.returnDate,
    this.productQuantityCase,
    this.productQuantityPcs,
    this.productQuantityPack,
    this.productQuantityBox,
    this.isCase,
    this.isPcs,
    this.isBox,
    this.isPack,
    this.invoice,
    this.customer,
    this.trip,
  }) {
    if (invoice != null) invoiceRef.target = invoice;
    if (customer != null) customerRef.target = customer;
    if (trip != null) tripRef.target = trip;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    productName,
    productDescription,
    reason,
    returnDate,
    productQuantityCase,
    productQuantityPcs,
    productQuantityPack,
    productQuantityBox,
    isCase,
    isPcs,
    isBox,
    isPack,
    invoice,
    customer,
    trip,
  ];
}
