import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class CollectionModel extends CollectionEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String? deliveryDataId;

  @Property()
  String? tripId;

  @Property()
  String? customerId;

  @Property()
  String? invoiceId;

  CollectionModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    DeliveryDataModel? deliveryData,
    TripModel? trip,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    List<InvoiceDataModel>? invoices,
    super.totalAmount,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    deliveryDataId = deliveryData?.id,
    tripId = trip?.id,
    customerId = customer?.id,
    invoiceId = invoice?.id,
    super(
      deliveryDataModel: deliveryData,
      tripData: trip,
      customerData: customer,
      invoiceData: invoice,
      invoicesList: invoices,
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
        invoicesList = invoicesData.map((invoice) {
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
      invoicesList = (json['invoices'] as List)
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
      totalAmount: totalAmount,
      deliveryData: deliveryDataModel,
      trip: tripModel,
      customer: customerModel,
      invoice: invoiceModel,
      invoices: invoicesList,
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
      'deliveryData': deliveryData.target?.id,
      'trip': trip.target?.id,
      'customer': customer.target?.id,
      'invoice': invoice.target?.id,
      'invoices': invoices.map((invoice) => invoice.id).toList(),
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  CollectionModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryDataModel? deliveryData,
    TripModel? trip,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    List<InvoiceDataModel>? invoices,
    double? totalAmount,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = CollectionModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      totalAmount: totalAmount ?? this.totalAmount,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
    
    // Handle deliveryData relation
    if (deliveryData != null) {
      model.deliveryData.target = deliveryData;
    } else if (this.deliveryData.target != null) {
      model.deliveryData.target = this.deliveryData.target;
    }
    
    // Handle trip relation
    if (trip != null) {
      model.trip.target = trip;
    } else if (this.trip.target != null) {
      model.trip.target = this.trip.target;
    }

    // Handle customer relation
    if (customer != null) {
      model.customer.target = customer;
    } else if (this.customer.target != null) {
      model.customer.target = this.customer.target;
    }

    // Handle invoice relation
    if (invoice != null) {
      model.invoice.target = invoice;
    } else if (this.invoice.target != null) {
      model.invoice.target = this.invoice.target;
    }

    // Handle invoices relation
    if (invoices != null) {
      model.invoices.clear();
      model.invoices.addAll(invoices);
    } else if (this.invoices.isNotEmpty) {
      model.invoices.clear();
      model.invoices.addAll(this.invoices);
    }
    
    return model;
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
    return 'CollectionModel(id: $id, deliveryData: ${deliveryData.target?.id}, trip: ${trip.target?.id}, customer: ${customer.target?.id}, invoice: ${invoice.target?.id}, invoices: ${invoices.length}, totalAmount: $totalAmount)';
  }
}
