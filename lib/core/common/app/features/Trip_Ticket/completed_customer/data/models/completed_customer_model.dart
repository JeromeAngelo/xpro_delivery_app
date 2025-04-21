import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CompletedCustomerModel extends CompletedCustomerEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  @Property(type: PropertyType.date)
  DateTime? timeCompleted;

  CompletedCustomerModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.deliveryNumber,
    super.storeName,
    super.ownerName,
    super.contactNumber,
    super.address,
    super.municipality,
    super.province,
    super.modeOfPayment,
    super.timeCompleted,
    super.totalAmount,
    super.invoicesList,
    super.transaction,
    super.returnList,
    super.customer,
    ModeOfPayment? paymentSelection,
    super.totalTime,
    List<DeliveryUpdateModel>? deliveryStatusList,
    TripModel? tripModel,
    this.tripId,
  }) : pocketbaseId = id ?? '',
       super(modeOfPaymentString: paymentSelection?.toString());

  factory CompletedCustomerModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Enhanced delivery status parsing
    final deliveryStatusList = (expandedData?['deliveryStatus'] as List?)
            ?.map((status) {
              if (status == null) return null;
              return DeliveryUpdateModel.fromJson(status is RecordModel
                  ? {
                      'id': status.id,
                      'collectionId': status.collectionId,
                      'collectionName': status.collectionName,
                      ...status.data,
                    }
                  : status as DataMap);
            })
            .whereType<DeliveryUpdateModel>()
            .toList() ??
        [];

    // Enhanced invoice parsing
    final invoicesList = (expandedData?['invoices'] as List?)
            ?.map((invoice) => InvoiceModel.fromJson({
                  'id': invoice['id'],
                  'collectionId': invoice['collectionId'],
                  'collectionName': invoice['collectionName'],
                  'invoiceNumber': invoice['invoiceNumber'],
                  'status': invoice['status'],
                  'productList': invoice['productsList'] ?? [],
                  'customer': invoice['customer'],
                  'created': invoice['created'],
                  'updated': invoice['updated'],
                }))
            .toList() ??
        [];

    // Map transaction
    final transactionData = expandedData?['transaction'];
    TransactionModel? transaction;
    if (transactionData != null) {
      if (transactionData is RecordModel) {
        transaction = TransactionModel.fromJson({
          'id': transactionData.id,
          'collectionId': transactionData.collectionId,
          'collectionName': transactionData.collectionName,
          ...transactionData.data,
        });
      } else if (transactionData is Map) {
        transaction = TransactionModel.fromJson(
            transactionData as Map<String, dynamic>);
      }
    }

    // Map customer
    final customerData = expandedData?['customer'];
    CustomerModel? customer;
    if (customerData != null) {
      if (customerData is RecordModel) {
        customer = CustomerModel.fromJson({
          'id': customerData.id,
          'collectionId': customerData.collectionId,
          'collectionName': customerData.collectionName,
          ...customerData.data,
        });
      } else if (customerData is Map) {
        customer = CustomerModel.fromJson(
            customerData as Map<String, dynamic>);
      }
    }

    // Map returns
    final returnList = (expandedData?['returns'] as List?)
            ?.map((returnItem) => ReturnModel.fromJson(returnItem as DataMap))
            .toList() ??
        [];

    return CompletedCustomerModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      deliveryNumber: json['deliveryNumber']?.toString(),
      ownerName: json['ownerName']?.toString(),
      storeName: json['storeName']?.toString(),
      contactNumber: json['contactNumber'] is String
          ? [json['contactNumber'] as String]
          : (json['contactNumber'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      address: json['address']?.toString(),
      municipality: json['municipality']?.toString(),
      province: json['province']?.toString(),
      modeOfPayment: json['modeOfPayment']?.toString(),
      paymentSelection: ModeOfPayment.values.firstWhere(
          (mode) => mode.toString() == 'ModeOfPayment.${json['modeOfPayment']}',
          orElse: () => ModeOfPayment.cashOnDelivery),
      deliveryStatusList: deliveryStatusList,
      invoicesList: invoicesList,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0.0'),
      timeCompleted: parseDate(json['timeCompleted']),
      transaction: transaction,
      returnList: returnList,
      customer: customer,
      totalTime: json['totalTime']?.toString(),
     
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'deliveryNumber': deliveryNumber ?? '',
      'storeName': storeName ?? '',
      'ownerName': ownerName ?? '',
      'contactNumber': contactNumber ?? '',
      'address': address ?? '',
      'municipality': municipality ?? '',
      'province': province ?? '',
      'modeOfPayment': modeOfPayment ?? '',
      'totalTime': totalTime ?? '',
      'timeCompleted': timeCompleted?.toIso8601String(),
      'deliveryStatus': deliveryStatus.map((status) => status.toJson()).toList(),
      'invoices': invoices.map((invoice) => invoice.toJson()).toList(),
      'transaction': transaction?.toJson(),
      'returns': returnList.map((r) => r.toJson()).toList(),
      'customer': customer?.toJson(),
      'trip': tripId ?? '',
      'totalAmount': totalAmount ?? '',
      'payment_selection': paymentSelection.toString().split('.').last,
      'created': null,
      'updated': null,
    };
  }
}
