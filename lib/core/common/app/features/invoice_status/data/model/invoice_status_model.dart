import 'package:pocketbase/pocketbase.dart';

import '../../../../../../typedefs/typedefs.dart';
import '../../../Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import '../../../Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import '../../../Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import '../../domain/entity/invoice_status_entity.dart';

class InvoiceStatusModel extends InvoiceStatusEntity {
  const InvoiceStatusModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.customer,
    super.invoiceData,
    super.tripStatus,
    super.deliveryData,
    super.created,
    super.updated,
  });

factory InvoiceStatusModel.fromJson(Map<String, dynamic> json) {
   DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Handle expanded data for customer relation
    final expandedData = json['expand'] as Map<String, dynamic>?;
    CustomerDataModel? customerModel;

    if (expandedData != null && expandedData.containsKey('customer')) {
      final customerData = expandedData['customer'];
      if (customerData != null) {
        if (customerData is RecordModel) {
          customerModel = CustomerDataModel.fromJson({
            'id': customerData.id,
            'collectionId': customerData.collectionId,
            'collectionName': customerData.collectionName,
            ...customerData.data,
          });
        } else if (customerData is Map) {
          customerModel = CustomerDataModel.fromJson(customerData as DataMap);
        }
      }
    }

   // Process deliveryData relation
    DeliveryDataModel? deliveryDataModel;
    if (expandedData != null && expandedData.containsKey('deliveryData')) {
      final deliveryDataData = expandedData['deliveryData'];
      if (deliveryDataData != null) {
        if (deliveryDataData is RecordModel) {
          deliveryDataModel = DeliveryDataModel.fromJson({
            'id': deliveryDataData.id,
            'collectionId': deliveryDataData.collectionId,
            'collectionName': deliveryDataData.collectionName,
            ...deliveryDataData.data,
            'expand': deliveryDataData.expand,
          });
        } else if (deliveryDataData is Map) {
          deliveryDataModel = DeliveryDataModel.fromJson(deliveryDataData as DataMap);
        }
      }
    } else if (json['deliveryData'] != null) {
      // If not expanded, just store the ID
      deliveryDataModel = DeliveryDataModel(id: json['deliveryData'].toString());
    }

     // Process invoice relation
    InvoiceDataModel? invoiceModel;
    if (expandedData != null && expandedData.containsKey('invoice')) {
      final invoiceData = expandedData['invoice'];
      if (invoiceData != null) {
        if (invoiceData is RecordModel) {
          invoiceModel = InvoiceDataModel.fromJson({
            'id': invoiceData.id,
            'collectionId': invoiceData.collectionId,
            'collectionName': invoiceData.collectionName,
            ...invoiceData.data,
            'expand': invoiceData.expand,
          });
        } else if (invoiceData is Map) {
          invoiceModel = InvoiceDataModel.fromJson(invoiceData as DataMap);
        }
      }
    } else if (json['invoice'] != null) {
      // If not expanded, just store the ID
      invoiceModel = InvoiceDataModel(id: json['invoice'].toString());
    }

    return InvoiceStatusModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      customer: customerModel,
      invoiceData: invoiceModel,
      tripStatus: json['tripStatus']?.toString(),
      deliveryData: deliveryDataModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
}

DataMap toJson(){
  return {
    'id': id,
    'collectionId': collectionId,
    'collectionName': collectionName,
    'customer': customer?.id ?? '',
    'invoiceData': invoiceData?.id ?? '',
    'tripStatus': tripStatus ?? '',
    'deliveryData': deliveryData?.id ?? '',
    'created': created?.toIso8601String(),
    'updated': updated?.toIso8601String(),
  };
}

InvoiceStatusModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    CustomerDataModel? customer,
    InvoiceDataModel? invoiceData,
    String? tripStatus,
    DeliveryDataModel? deliveryData,
    DateTime? created,
    DateTime? updated,
  }) {
    return InvoiceStatusModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      customer: customer ?? this.customer,
      invoiceData: invoiceData ?? this.invoiceData,
      tripStatus: tripStatus ?? this.tripStatus,
      deliveryData: deliveryData ?? this.deliveryData,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }


}
