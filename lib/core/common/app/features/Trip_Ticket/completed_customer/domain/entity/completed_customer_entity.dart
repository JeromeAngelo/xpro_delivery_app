import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
@Entity()
class CompletedCustomerEntity extends Equatable {
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
  DateTime? timeCompleted;
  double? totalAmount;
  String? totalTime;
  @Property()
  final List<InvoiceModel> invoicesList;
  final ToMany<InvoiceModel> invoices = ToMany<InvoiceModel>();
  
  final ToMany<DeliveryUpdateModel> deliveryStatus = ToMany<DeliveryUpdateModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();

  @Property()
  final TransactionModel? transaction;
  final ToOne<TransactionModel> transactionRef = ToOne<TransactionModel>();

  @Property()
  final List<ReturnModel> returnList;
  final ToMany<ReturnModel> returns = ToMany<ReturnModel>();

  @Property()
  final CustomerModel? customer;
  final ToOne<CustomerModel> customerRef = ToOne<CustomerModel>();

    @Property()
    String? modeOfPaymentString;
    
    ModeOfPayment get paymentSelection => ModeOfPayment.values.firstWhere(
      (mode) => mode.toString() == modeOfPaymentString,
      orElse: () => ModeOfPayment.cashOnDelivery,
    );


  CompletedCustomerEntity({
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
    this.timeCompleted,
    this.totalAmount,
    this.totalTime,
    this.modeOfPaymentString,
    List<InvoiceModel>? invoicesList,
    this.transaction,
    List<ReturnModel>? returnList,
    this.customer,
    List<DeliveryUpdateModel>? deliveryStatusList,
    TripModel? tripModel,
  }) : invoicesList = invoicesList ?? [],
       returnList = returnList ?? [] {
    if (deliveryStatusList != null) deliveryStatus.addAll(deliveryStatusList);
    if (invoicesList != null) invoices.addAll(invoicesList);
    if (tripModel != null) trip.target = tripModel;
    if (transaction != null) transactionRef.target = transaction;
    if (returnList != null) returns.addAll(returnList);
    if (customer != null) customerRef.target = customer;
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
    timeCompleted,
    totalAmount,
    invoicesList,
    invoices,
    deliveryStatus,
    trip.target?.id,
    transaction,
    transactionRef,
    returnList,
    returns,
    customer,
    customerRef,
    modeOfPaymentString,
  ];
}
