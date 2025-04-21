import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';

import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CustomerModel extends CustomerEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  CustomerModel({
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
    super.deliveryStatusList,
    super.numberOfInvoices,
    super.totalAmount,
    super.invoicesList,
    super.tripModel,
    super.latitude,
    super.longitude,
    super.created,
    super.updated,
    super.returnList,
    super.transactionList,
    super.totalTime,
    ModeOfPayment? paymentSelection,
    super.confirmedTotalPayment,
    super.hasNotes,
    this.tripId,
    super.notes,
    super.remarks,
  })  : pocketbaseId = id ?? '',
        super(modeOfPaymentString: paymentSelection?.toString());
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
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

    // Handle trip data
    final tripData = expandedData?['trip'];
    TripModel? tripModel;

    if (tripData != null) {
      if (tripData is RecordModel) {
        tripModel = TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
        });
      } else if (tripData is List && tripData.isNotEmpty) {
        final firstTrip = tripData.first as RecordModel;
        tripModel = TripModel.fromJson({
          'id': firstTrip.id,
          'collectionId': firstTrip.collectionId,
          'collectionName': firstTrip.collectionName,
          ...firstTrip.data,
        });
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
      }
    }

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

    // Enhanced invoice parsing with direct access to expanded data
    final invoicesList = (expandedData?['invoices(customer)'] as List?)
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

    final transactionList = (expandedData?['transactions'] as List?)
            ?.map((transaction) =>
                TransactionModel.fromJson(transaction as DataMap))
            .toList() ??
        [];

    final returnList = (expandedData?['returns'] as List?)
            ?.map((returnItem) => ReturnModel.fromJson(returnItem as DataMap))
            .toList() ??
        [];

    return CustomerModel(
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
      numberOfInvoices: invoicesList.length,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0.0'),
      confirmedTotalPayment:
          double.tryParse(json['confirmedTotalPayment']?.toString() ?? '0.0'),
      hasNotes: json['hasNotes'] as bool,
      tripModel: tripModel,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      returnList: returnList,
      remarks: json['remarks']?.toString(),
      notes: json['notes']?.toString(),
      totalTime: json['totalTime']?.toString(),
      transactionList: transactionList,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
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
      'confirmedTotalPayment': confirmedTotalPayment ?? '',
      'hasNotes': hasNotes ?? '',
      'deliveryStatus':
          deliveryStatus.map((status) => status.toJson()).toList(),
      'invoices': invoices.map((invoice) => invoice.toJson()).toList(),
      'trip': tripId ?? '',
      'numberOfInvoices': numberOfInvoices ?? '',
      'totalAmount': totalAmount ?? '',
      'returnList': returnList,
      'transactionList': transactionList,
      'latitude': latitude,
      'longitude': longitude,
      'payment_selection': paymentSelection.toString().split('.').last,
      'notes': notes,
      'remarks': remarks,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }
}
