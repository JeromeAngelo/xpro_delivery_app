import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/invoice_status.dart';

@Entity()
class DeliveryDataModel extends DeliveryDataEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

 

  DeliveryDataModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    List<InvoiceDataModel>? invoices,
    TripModel? trip,
    List<DeliveryUpdateModel>? deliveryUpdates,
    List<InvoiceItemsModel>? invoiceItems,
    super.paymentMode,
    super.deliveryNumber,
    super.hasTrip,
    super.totalDeliveryTime,
    super.paymentSelection, // Add the enum parameter
    super.invoiceStatus,
    super.storeName,
    super.ownerName,
    super.contactNumber,
    super.barangay,
    super.municipality,
    super.province,
    super.refID,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    super(
      customerData: customer,
      invoiceData: invoice,
      invoicesList: invoices,
      tripData: trip,
      deliveryUpdatesList: deliveryUpdates,
      invoiceItemsList: invoiceItems,
    );

  factory DeliveryDataModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse payment selection enum
    ModeOfPayment? parsePaymentSelection(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        final enumValue = value.toString().toLowerCase();
        switch (enumValue) {
          case 'banktransfer':
            return ModeOfPayment.bankTransfer;
          case 'cashondelivery':
            return ModeOfPayment.cashOnDelivery;
          case 'cheque':
            return ModeOfPayment.cheque;
          case 'ewallet':
            return ModeOfPayment.eWallet;
          default:
            debugPrint('⚠️ Unknown payment mode: $enumValue');
            return null;
        }
      } catch (e) {
        debugPrint('❌ Error parsing payment selection: $e');
        return null;
      }
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;
    
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
    
    // Process deliveryUpdates relation (multiple)
    List<DeliveryUpdateModel> deliveryUpdatesList = [];
    if (expandedData != null && expandedData.containsKey('deliveryUpdates')) {
      final deliveryUpdatesData = expandedData['deliveryUpdates'];
      if (deliveryUpdatesData != null && deliveryUpdatesData is List) {
        deliveryUpdatesList = deliveryUpdatesData.map((update) {
          if (update is RecordModel) {
            return DeliveryUpdateModel.fromJson({
              'id': update.id,
              'collectionId': update.collectionId,
              'collectionName': update.collectionName,
              ...update.data,
              'expand': update.expand,
            });
          } else if (update is Map) {
            return DeliveryUpdateModel.fromJson(update as DataMap);
          }
          // If it's just an ID string, create a minimal model
          return DeliveryUpdateModel(id: update.toString());
        }).toList();
      }
    } else if (json['deliveryUpdates'] != null && json['deliveryUpdates'] is List) {
      // If not expanded, just store the IDs
      deliveryUpdatesList = (json['deliveryUpdates'] as List)
          .map((id) => DeliveryUpdateModel(id: id.toString()))
          .toList();
    }

    // Process invoiceItems relation (multiple)
    List<InvoiceItemsModel> invoiceItemsList = [];
    if (expandedData != null && expandedData.containsKey('invoiceItems')) {
      final invoiceItemsData = expandedData['invoiceItems'];
      if (invoiceItemsData != null && invoiceItemsData is List) {
        invoiceItemsList = invoiceItemsData.map((item) {
          if (item is RecordModel) {
            return InvoiceItemsModel.fromJson({
              'id': item.id,
              'collectionId': item.collectionId,
              'collectionName': item.collectionName,
              ...item.data,
              'expand': item.expand,
            });
          } else if (item is Map) {
            return InvoiceItemsModel.fromJson(item as DataMap);
          }
          // If it's just an ID string, create a minimal model
          return InvoiceItemsModel(id: item.toString());
        }).toList();
      }
    } else if (json['invoiceItems'] != null && json['invoiceItems'] is List) {
      // If not expanded, just store the IDs
      invoiceItemsList = (json['invoiceItems'] as List)
          .map((id) => InvoiceItemsModel(id: id.toString()))
          .toList();
    }

    return DeliveryDataModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      paymentMode: json['paymentMode']?.toString(),
      hasTrip: json['hasTrip'] as bool? ?? false,
      deliveryNumber: json['deliveryNumber']?.toString(),
      paymentSelection: parsePaymentSelection(json['paymentSelection']), // Parse the enum
      customer: customerModel,
       invoiceStatus: InvoiceStatus.values.firstWhere(
        (e) => e.name == (json['invoiceStatus'] ?? 'none'),
        orElse: () => InvoiceStatus.none,
      ),
      invoice: invoiceModel,
      invoices: invoicesList,
      trip: tripModel,
      totalDeliveryTime: json['totalDeliveryTime'],
      deliveryUpdates: deliveryUpdatesList,
      invoiceItems: invoiceItemsList,
      storeName: json['storeName']?.toString(),
      ownerName: json['ownerName']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      barangay: json['barangay']?.toString(),
      municipality: json['municipality']?.toString(),
      province: json['province']?.toString(),
      refID: json['refID']?.toString(),
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    // Convert enum to string for JSON serialization
    String? paymentSelectionString;
    if (paymentSelection != null) {
      switch (paymentSelection!) {
        case ModeOfPayment.bankTransfer:
          paymentSelectionString = 'bankTransfer';
          break;
        case ModeOfPayment.cashOnDelivery:
          paymentSelectionString = 'cashOnDelivery';
          break;
        case ModeOfPayment.cheque:
          paymentSelectionString = 'cheque';
          break;
        case ModeOfPayment.eWallet:
          paymentSelectionString = 'eWallet';
          break;
      }
    }

    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'paymentMode': paymentMode,
      'hasTrip': hasTrip ?? false,
      'deliveryNumber': deliveryNumber,
      'paymentSelection': paymentSelectionString, // Add enum to JSON
      'customer': customer.target?.id,
      'invoice': invoice.target?.id,
      'invoices': invoices.map((invoice) => invoice.id).toList(),
      'trip': trip.target?.id,
      'totalDeliveryTime': totalDeliveryTime,
      'deliveryUpdates': deliveryUpdates.map((update) => update.id).toList(),
      'invoiceItems': invoiceItems.map((item) => item.id).toList(),
      'invoiceStatus': invoiceStatus,
      'storeName': storeName,
      'ownerName': ownerName,
      'contactNumber': contactNumber,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'refID': refID,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  DeliveryDataModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    List<InvoiceDataModel>? invoices,
    TripModel? trip,
    List<DeliveryUpdateModel>? deliveryUpdates,
    List<InvoiceItemsModel>? invoiceItems,
    InvoiceStatus? invoiceStatus,
    String? paymentMode,
    String? deliveryNumber,
    bool? hasTrip,
    String? totalDeliveryTime,
    ModeOfPayment? paymentSelection, // Add enum to copyWith
    String? storeName,
    String? ownerName,
    String? contactNumber,
    String? barangay,
    String? municipality,
    String? province,
    String? refID,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = DeliveryDataModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      hasTrip: hasTrip ?? this.hasTrip,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      totalDeliveryTime: totalDeliveryTime ?? this.totalDeliveryTime,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      paymentSelection: paymentSelection ?? this.paymentSelection, // Add enum to copyWith
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      contactNumber: contactNumber ?? this.contactNumber,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      refID: refID ?? this.refID,
      objectBoxId: objectBoxId,
    );
    
    // Handle relations
    if (customer != null) {
      model.customer.target = customer;
    } else if (this.customer.target != null) {
      model.customer.target = this.customer.target;
    }
    
    if (invoice != null) {
      model.invoice.target = invoice;
    } else if (this.invoice.target != null) {
      model.invoice.target = this.invoice.target;
    }
    
    if (invoices != null) {
      model.invoices.clear();
      model.invoices.addAll(invoices);
    } else if (this.invoices.isNotEmpty) {
      model.invoices.clear();
      model.invoices.addAll(this.invoices);
    }
    
    if (trip != null) {
      model.trip.target = trip;
    } else if (this.trip.target != null) {
      model.trip.target = this.trip.target;
    }
    
    if (deliveryUpdates != null) {
      model.deliveryUpdates.clear();
      model.deliveryUpdates.addAll(deliveryUpdates);
    } else if (this.deliveryUpdates.isNotEmpty) {
      model.deliveryUpdates.clear();
      model.deliveryUpdates.addAll(this.deliveryUpdates);
    }
    
    if (invoiceItems != null) {
      model.invoiceItems.clear();
      model.invoiceItems.addAll(invoiceItems);
    } else if (this.invoiceItems.isNotEmpty) {
      model.invoiceItems.clear();
      model.invoiceItems.addAll(this.invoiceItems);
    }
    
    return model;
  }

   @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryDataModel(id: $id, customer: ${customer.target?.id}, invoice: ${invoice.target?.id}, invoices: ${invoices.length}, trip: ${trip.target?.id}, deliveryUpdates: ${deliveryUpdates.length}, invoiceItems: ${invoiceItems.length}, paymentMode: $paymentMode, paymentSelection: $paymentSelection, deliveryNumber: $deliveryNumber, storeName: $storeName, ownerName: $ownerName, contactNumber: $contactNumber, barangay: $barangay, municipality: $municipality, province: $province, refID: $refID)';
  }
}
