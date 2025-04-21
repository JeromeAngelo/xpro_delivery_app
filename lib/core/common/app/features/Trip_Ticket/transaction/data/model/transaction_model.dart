import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/data/models/completed_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'dart:io';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/enums/transaction_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
@Entity()
class TransactionModel extends TransactionEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String? pocketbaseId;

  @Property()
  String? customerId;

  @Property()
  String? completedCustomerId;

  @Property()
  DateTime? transactionDate;

@Property()
  String? tripId;
  TransactionModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.customerModel,
    super.customerName,
    super.totalAmount,
    super.signature,
    super.customerImage,
    List<InvoiceModel>? invoices,
    super.deliveryNumber,
    super.transactionDate,
    TransactionStatus? transactionStatus,
    super.createdAt,
    super.updatedAt,
    ModeOfPayment? modeOfPayment,
    super.isCompleted,
    super.pdf,
    super.refNumber,
    super.trip,
    super.completedCustomer,
  })  : pocketbaseId = id ?? '',
        super(
          invoicesList: invoices,
          transactionStatusString: transactionStatus?.toString(),
          modeOfPaymentString: modeOfPayment?.toString(),
        );

  factory TransactionModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    final invoicesList = (expandedData?['invoices'] as List?)?.map((invoice) {
          if (invoice is RecordModel) {
            return InvoiceModel.fromJson({
              'id': invoice.id,
              'collectionId': invoice.collectionId,
              'collectionName': invoice.collectionName,
              ...invoice.data,
            });
          }
          return InvoiceModel.fromJson(invoice as DataMap);
        }).toList() ??
        [];

    final trip = expandedData?['trip'] != null
        ? TripModel.fromJson(expandedData!['trip'] is RecordModel
            ? {
                'id': expandedData['trip'].id,
                'collectionId': expandedData['trip'].collectionId,
                'collectionName': expandedData['trip'].collectionName,
                ...expandedData['trip'].data,
              }
            : expandedData['trip'] as DataMap)
        : null;

    final customer = expandedData?['customer'] != null
        ? CustomerModel.fromJson(expandedData!['customer'] is RecordModel
            ? {
                'id': expandedData['customer'].id,
                'collectionId': expandedData['customer'].collectionId,
                'collectionName': expandedData['customer'].collectionName,
                ...expandedData['customer'].data,
              }
            : expandedData['customer'] as DataMap)
        : null;

    final completedCustomer = expandedData?['completedCustomer'] != null
        ? CompletedCustomerModel.fromJson(
            expandedData!['completedCustomer'] is RecordModel
                ? {
                    'id': expandedData['completedCustomer'].id,
                    'collectionId': expandedData['completedCustomer'].collectionId,
                    'collectionName': expandedData['completedCustomer'].collectionName,
                    ...expandedData['completedCustomer'].data,
                  }
                : expandedData['completedCustomer'] as DataMap)
        : null;

    return TransactionModel(
      id: json['id'].toString(),
      collectionId: json['collectionId'].toString(),
      collectionName: json['collectionName'].toString(),
      customerModel: customer,
      customerName: json['customerName'].toString(),
      totalAmount: json['totalAmount'].toString(),
      deliveryNumber: json['deliveryNumber'].toString(),
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      transactionStatus: TransactionStatus.values.firstWhere(
          (status) =>
              status.toString() ==
              'TransactionStatus.${json['transactionStatus']}',
          orElse: () => TransactionStatus.pending),
      modeOfPayment: ModeOfPayment.values.firstWhere(
          (mode) => mode.toString() == 'ModeOfPayment.${json['modeOfPayment']}',
          orElse: () => ModeOfPayment.cashOnDelivery),
      isCompleted: json['isCompleted'] as bool,
      invoices: invoicesList,
      refNumber: json['refNumber'].toString(),
      signature: null,
      customerImage: json['customerImage'].toString(),
      pdf: null,
      trip: trip,
      completedCustomer: completedCustomer,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'customer': customer.target?.id,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'deliveryNumber': deliveryNumber,
      'transactionDate': transactionDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'transactionStatus': transactionStatus.toString().split('.').last,
      'modeOfPayment': modeOfPayment.toString().split('.').last,
      'isCompleted': isCompleted,
      'refNumber': refNumber,
      'customerImage': customerImage,
      'invoice': invoices.map((inv) => inv.id).toList(),
      'trip': trip?.toJson(),
      'completedCustomer': completedCustomer?.toJson(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    CustomerModel? customerModel,
    String? customerName,
    String? totalAmount,
    File? signature,
    String? customerImage,
    List<InvoiceModel>? invoices,
    String? deliveryNumber,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionStatus? transactionStatus,
    ModeOfPayment? modeOfPayment,
    bool? isCompleted,
    File? pdf,
    String? refNumber,
    TripModel? trip,
    CompletedCustomerModel? completedCustomer,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      customerModel: customerModel ?? customer.target,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      signature: signature ?? this.signature,
      customerImage: customerImage ?? this.customerImage,
      invoices: invoices ?? List<InvoiceModel>.from(this.invoices),
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      isCompleted: isCompleted ?? this.isCompleted,
      pdf: pdf ?? this.pdf,
      refNumber: refNumber ?? this.refNumber,
      trip: trip ?? tripRef.target,
      completedCustomer: completedCustomer ?? completedCustomerRef.target,
    );
  }
}
