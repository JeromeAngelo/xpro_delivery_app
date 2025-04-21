import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

@Entity()
class InvoiceEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? invoiceNumber;
  bool? isCompleted;
  @Property()
  final List<ProductModel> productsList;
  final ToMany<ProductModel> productList = ToMany<ProductModel>();

  InvoiceStatus? status;

  final ToOne<CustomerModel> customer = ToOne<CustomerModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();

  double? totalAmount;
  double? confirmTotalAmount;
  String? customerDeliveryStatus;
  DateTime? created;
  DateTime? updated;

  InvoiceEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.invoiceNumber,
    List<ProductModel>? productsList,
    this.status,
    CustomerModel? customer,
    TripModel? trip,
    this.totalAmount,
    this.confirmTotalAmount,
    this.customerDeliveryStatus,
    this.isCompleted,
    this.created,
    this.updated,
  }) : productsList = productsList ?? [] {
    if (productsList != null) this.productList.addAll(productsList);
    if (customer != null) this.customer.target = customer;
    if (trip != null) this.trip.target = trip;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    invoiceNumber,
    productList,
    status,
    customer.target?.id,
    trip.target?.id,
    totalAmount,
    confirmTotalAmount,
    customerDeliveryStatus,
    isCompleted,
    created,
    updated,
  ];
}
