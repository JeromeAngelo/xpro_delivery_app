import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';

@Entity()
class CustomerEntity extends Equatable {
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
  String? totalTime;
  bool? hasNotes;
  double? confirmedTotalPayment;
  String? notes;
  String? remarks;
  @Property()
  final List<TransactionModel> transactionList;
  final ToMany<TransactionModel> transactions = ToMany<TransactionModel>();

  @Property()
  final List<ReturnModel> returnList;
  final ToMany<ReturnModel> returns = ToMany<ReturnModel>();

  @Property()
  final List<InvoiceModel> invoicesList;
  final ToMany<InvoiceModel> invoices = ToMany<InvoiceModel>();

  final ToMany<DeliveryUpdateModel> deliveryStatus =
      ToMany<DeliveryUpdateModel>();

  final ToOne<TripModel> trip = ToOne<TripModel>();

  @Property()
  String? modeOfPaymentString;

  ModeOfPayment get paymentSelection => ModeOfPayment.values.firstWhere(
        (mode) => mode.toString() == modeOfPaymentString,
        orElse: () => ModeOfPayment.cashOnDelivery,
      );

  int? numberOfInvoices;
  double? totalAmount;
  String? latitude;
  String? longitude;
  DateTime? created;
  DateTime? updated;

  CustomerEntity({
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
    this.totalTime,
    List<DeliveryUpdateModel>? deliveryStatusList,
    this.numberOfInvoices,
    this.totalAmount,
    List<InvoiceModel>? invoicesList,
    TripModel? tripModel,
    this.confirmedTotalPayment,
    this.hasNotes,
    this.latitude,
    this.longitude,
    this.created,
    this.updated,
    this.notes,
    this.remarks,
    this.modeOfPaymentString,
    List<ReturnModel>? returnList,
    List<TransactionModel>? transactionList,
  })  : invoicesList = invoicesList ?? [],
        returnList = returnList ?? [],
        transactionList = transactionList ?? [] {
    if (deliveryStatusList != null) deliveryStatus.addAll(deliveryStatusList);
    if (invoicesList != null) invoices.addAll(invoicesList);
    if (returnList != null) returns.addAll(returnList);
    if (transactionList != null) transactions.addAll(transactionList);
    if (tripModel != null) trip.target = tripModel;
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
        deliveryStatus,
        numberOfInvoices,
        totalAmount,
        invoicesList,
        invoices,
        trip.target?.id,
        latitude,
        longitude,
        created,
        updated,
        returnList,
        transactionList,
        totalTime,
        notes,
        remarks,
        modeOfPaymentString,
        hasNotes,
        confirmedTotalPayment
      ];
}
