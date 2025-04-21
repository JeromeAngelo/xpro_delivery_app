import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/enums/transaction_status.dart';
import 'dart:io';
@Entity()
class TransactionEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? customerName;
  final String? totalAmount;
  String? refNumber;
  final File? signature;
  String? customerImage;
  final ToMany<InvoiceEntity> invoices = ToMany<InvoiceEntity>();
  final String? deliveryNumber;
  final DateTime? transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isCompleted;
  final File? pdf;

  @Property()
  String? transactionStatusString;

  @Property()
  String? modeOfPaymentString;

  @Property()
  final TripModel? trip;
  final ToOne<TripModel> tripRef = ToOne<TripModel>();

  // Enhanced customer relation
  @Property()
  final CustomerModel? customerModel;
  final ToOne<CustomerModel> customer = ToOne<CustomerModel>();

  // Add completed customer relation
  @Property()
  final CompletedCustomerModel? completedCustomer;
  final ToOne<CompletedCustomerModel> completedCustomerRef = ToOne<CompletedCustomerModel>();

  TransactionEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.customerName,
    this.refNumber,
    this.totalAmount,
    this.signature,
    this.customerImage,
    List<InvoiceEntity>? invoicesList,
    this.deliveryNumber,
    this.transactionDate,
    this.transactionStatusString,
    this.modeOfPaymentString,
    this.createdAt,
    this.updatedAt,
    this.isCompleted,
    this.pdf,
    this.trip,
    this.customerModel,
    this.completedCustomer,
  }) {
    if (invoicesList != null) {
      invoices.addAll(invoicesList);
    }
    if (trip != null) tripRef.target = trip;
    if (customerModel != null) customer.target = customerModel;
    if (completedCustomer != null) completedCustomerRef.target = completedCustomer;
  }

  TransactionStatus get transactionStatus =>
      TransactionStatus.values.firstWhere(
        (status) => status.toString() == transactionStatusString,
        orElse: () => TransactionStatus.pending,
      );

  ModeOfPayment get modeOfPayment => ModeOfPayment.values.firstWhere(
        (mode) => mode.toString() == modeOfPaymentString,
        orElse: () => ModeOfPayment.cashOnDelivery,
      );

  @override
  List<Object?> get props => [
        id,
        customerModel,
        customerName,
        totalAmount,
        signature,
        customerImage,
        invoices,
        deliveryNumber,
        transactionDate,
        transactionStatusString,
        createdAt,
        updatedAt,
        modeOfPaymentString,
        refNumber,
        isCompleted,
        pdf,
        trip,
        tripRef,
        customer,
        completedCustomer,
        completedCustomerRef,
      ];
}
