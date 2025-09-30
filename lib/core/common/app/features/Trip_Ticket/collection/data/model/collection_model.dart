import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../../../../../../../typedefs/typedefs.dart';
import '../../../trip/data/models/trip_models.dart';
import '../../../customer_data/data/model/customer_data_model.dart';
import '../../../delivery_data/data/model/delivery_data_model.dart';
import '../../../invoice_data/data/model/invoice_data_model.dart';
import '../../../invoice_data/domain/entity/invoice_data_entity.dart';
import '../../domain/entity/collection_entity.dart';


class CollectionModel extends CollectionEntity {
  String pocketbaseId;

  CollectionModel({
    super.id,
    super.collectionId,
    super.collectionName,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    TripModel? trip,
    DeliveryDataModel? deliveryData,
    List<InvoiceDataModel>? invoices, // 
    super.totalAmount,
    super.status,
    super.created,
    super.updated,
  }) : 
    pocketbaseId = id ?? '',
    super(
      customer: customer,
      invoice: invoice,
      trip: trip,
      deliveryData: deliveryData,
    );

  factory CollectionModel.fromJson(DataMap json) {
    debugPrint('🔧 CollectionModel.fromJson: Processing collection data');
    debugPrint('📋 Raw JSON keys: ${json.keys.toList()}');
    debugPrint('📋 Collection ID from JSON: ${json['id']}');
    debugPrint('📋 Total Amount from JSON: ${json['totalAmount']}');

    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Add safe double parsing
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        debugPrint('📊 Parsed totalAmount "$value" to: $parsed');
        return parsed;
      }
      debugPrint('⚠️ Could not parse totalAmount: $value (${value.runtimeType})');
      return null;
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;
    
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
    
    // Process trip relation
    TripModel? tripModel;
    if (expandedData != null && expandedData.containsKey('trip')) {
      final tripData = expandedData['trip'];
      if (tripData != null) {
        if (tripData is RecordModel) {
          tripModel = TripModel.fromJson({
            'id': tripData.id,
            'collectionId': tripData.collectionId,
            'collectionName': tripData.collectionName,
            ...tripData.data,
            'expand': tripData.expand,
          });
        } else if (tripData is Map) {
          tripModel = TripModel.fromJson(tripData as DataMap);
        }
      }
    } else if (json['trip'] != null) {
      // If not expanded, just store the ID
      tripModel = TripModel(id: json['trip'].toString());
    }

    // Process customer relation
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
            'expand': customerData.expand,
          });
        } else if (customerData is Map) {
          customerModel = CustomerDataModel.fromJson(customerData as DataMap);
        }
      }
    } else if (json['customer'] != null) {
      // If not expanded, just store the ID
      customerModel = CustomerDataModel(id: json['customer'].toString());
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


    // Process invoices relation (multiple)
    List<InvoiceDataModel> invoicesList = [];
    if (expandedData != null && expandedData.containsKey('invoices')) {
      final invoicesData = expandedData['invoices'];
      if (invoicesData != null && invoicesData is List) {
        invoicesList =
            invoicesData.map((invoice) {
              if (invoice is RecordModel) {
                return InvoiceDataModel.fromJson({
                  'id': invoice.id,
                  'collectionId': invoice.collectionId,
                  'collectionName': invoice.collectionName,
                  ...invoice.data,
                  'expand': invoice.expand,
                });
              } else if (invoice is Map) {
                return InvoiceDataModel.fromJson(invoice as DataMap);
              }
              // If it's just an ID string, create a minimal model
              return InvoiceDataModel(id: invoice.toString());
            }).toList();
      }
    } else if (json['invoices'] != null && json['invoices'] is List) {
      // If not expanded, just store the IDs
      invoicesList =
          (json['invoices'] as List)
              .map((id) => InvoiceDataModel(id: id.toString()))
              .toList();
    }

    // Parse totalAmount with fallback to invoice totalAmount
    double? totalAmount = parseDouble(json['totalAmount']);
    if ((totalAmount == null || totalAmount == 0) && invoiceModel?.totalAmount != null) {
      totalAmount = invoiceModel!.totalAmount;
      debugPrint('🔄 Using invoice totalAmount as fallback: $totalAmount');
    }

    debugPrint('🔗 Relations summary for collection ${json['id']}:');
    debugPrint('   - DeliveryData: ${deliveryDataModel?.id ?? "null"}');
    debugPrint('   - Trip: ${tripModel?.id ?? "null"}');
    debugPrint('   - Customer: ${customerModel?.id ?? "null"} (${customerModel?.name ?? "null"})');
    debugPrint('   - Invoice: ${invoiceModel?.id ?? "null"} (Amount: ${invoiceModel?.totalAmount ?? "null"})');
    debugPrint('   - Final totalAmount: $totalAmount');

    return CollectionModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      status: json['status']?.toString(),
      totalAmount: totalAmount,
      deliveryData: deliveryDataModel,
      trip: tripModel,
      customer: customerModel,
            invoices: invoicesList,

      invoice: invoiceModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'totalAmount': totalAmount?.toString(),
      'deliveryData': deliveryData?.id,
      'trip': trip?.id,
      'status': status,
      'customer': customer?.id,
            'invoices': invoices?.map((invoice) => invoice.id).toList(),

      'invoice': invoice?.id,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }
  @override
  CollectionModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryDataEntity? deliveryData,
    TripEntity? trip,
    String? status,
    CustomerDataEntity? customer,
        List<InvoiceDataModel>? invoices,

    InvoiceDataEntity? invoice,
    double? totalAmount,
    DateTime? created,
    DateTime? updated,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      customer: customer != null 
          ? (customer is CustomerDataModel 
              ? customer 
              : CustomerDataModel(
                  id: customer.id,
                  collectionId: customer.collectionId,
                  collectionName: customer.collectionName,
                  name: customer.name,
                  created: customer.created,
                  updated: customer.updated,
                ))
          : (this.customer is CustomerDataModel 
              ? this.customer as CustomerDataModel 
              : this.customer != null 
                  ? CustomerDataModel(
                      id: this.customer!.id,
                      collectionId: this.customer!.collectionId,
                      collectionName: this.customer!.collectionName,
                      name: this.customer!.name,
                      created: this.customer!.created,
                      updated: this.customer!.updated,
                    )
                  : null),
      invoice: invoice != null 
          ? (invoice is InvoiceDataModel 
              ? invoice 
              : InvoiceDataModel(
                  id: invoice.id,
                  collectionId: invoice.collectionId,
                  collectionName: invoice.collectionName,
                  refId: invoice.refId,
                  name: invoice.name,
                  documentDate: invoice.documentDate,
                  totalAmount: invoice.totalAmount,
                  volume: invoice.volume,
                  weight: invoice.weight,
                  created: invoice.created,
                  updated: invoice.updated,
                  customer: invoice.customer,
                ))
          : (this.invoice is InvoiceDataModel 
              ? this.invoice as InvoiceDataModel 
              : this.invoice != null 
                  ? InvoiceDataModel(
                      id: this.invoice!.id,
                      collectionId: this.invoice!.collectionId,
                      collectionName: this.invoice!.collectionName,
                      refId: this.invoice!.refId,
                      name: this.invoice!.name,
                      documentDate: this.invoice!.documentDate,
                      totalAmount: this.invoice!.totalAmount,
                      volume: this.invoice!.volume,
                      weight: this.invoice!.weight,
                      created: this.invoice!.created,
                      updated: this.invoice!.updated,
                      customer: this.invoice!.customer,
                    )
                  : null),
                  invoices:
          invoices ??
          (this.invoices
              ?.map(
                (invoice) =>
                    invoice is InvoiceDataModel
                        ? invoice
                        : InvoiceDataModel(id: invoice.id),
              )
              .toList()),
      trip: trip != null 
          ? (trip is TripModel 
              ? trip 
              : TripModel(id: trip.id))
          : (this.trip is TripModel 
              ? this.trip as TripModel 
              : this.trip != null 
                  ? TripModel(id: this.trip!.id)
                  : null),
      deliveryData: deliveryData != null 
          ? (deliveryData is DeliveryDataModel 
              ? deliveryData 
              : DeliveryDataModel(id: deliveryData.id))
          : (this.deliveryData is DeliveryDataModel 
              ? this.deliveryData as DeliveryDataModel 
              : this.deliveryData != null 
                  ? DeliveryDataModel(id: this.deliveryData!.id)
                  : null),
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CollectionModel('
        'id: $id, '
        'deliveryData: ${deliveryData?.id}, '
        'trip: ${trip?.id}, '
        'customer: ${customer?.id}, '
        'status: $status, '
        'invoice: ${invoice?.id}, '
        'totalAmount: $totalAmount'
        ')';
  }
}
