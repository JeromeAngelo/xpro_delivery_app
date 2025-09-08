import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

class DeliveryDataModel extends DeliveryDataEntity {
  int objectBoxId = 0;
  String pocketbaseId;

  DeliveryDataModel({
    super.id,
    super.collectionId,
    super.collectionName,
    CustomerDataModel? customer,
    InvoiceDataModel? invoice,
    TripModel? trip,
    List<DeliveryUpdateModel>? deliveryUpdates,
    List<InvoiceItemsModel>? invoiceItems,
    List<InvoiceDataModel>? invoices,
    super.pinLang,
    super.pinLong,
    super.deliveryNumber,
    super.hasTrip,
    super.created,

    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '',
       super(
         customer: customer,
         invoice: invoice,
         trip: trip,
         invoices: invoices ?? [],
         deliveryUpdates: deliveryUpdates ?? [],
         invoiceItems: invoiceItems,
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

    // Add this after the deliveryUpdates processing section:

    // Process invoiceItems relation (multiple)
    List<InvoiceItemsModel> invoiceItemsList = [];
    if (expandedData != null && expandedData.containsKey('invoiceItems')) {
      final invoiceItemsData = expandedData['invoiceItems'];
      if (invoiceItemsData != null && invoiceItemsData is List) {
        invoiceItemsList =
            invoiceItemsData.map((item) {
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
      invoiceItemsList =
          (json['invoiceItems'] as List)
              .map((id) => InvoiceItemsModel(id: id.toString()))
              .toList();
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

    // Process deliveryUpdates relation (multiple)
    List<DeliveryUpdateModel> deliveryUpdatesList = [];
    if (expandedData != null && expandedData.containsKey('deliveryUpdates')) {
      final deliveryUpdatesData = expandedData['deliveryUpdates'];
      if (deliveryUpdatesData != null && deliveryUpdatesData is List) {
        deliveryUpdatesList =
            deliveryUpdatesData.map((update) {
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
    } else if (json['deliveryUpdates'] != null &&
        json['deliveryUpdates'] is List) {
      // If not expanded, just store the IDs
      deliveryUpdatesList =
          (json['deliveryUpdates'] as List)
              .map((id) => DeliveryUpdateModel(id: id.toString()))
              .toList();
    }

    return DeliveryDataModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      hasTrip: json['hasTrip'] as bool,
      deliveryNumber: json['deliveryNumber']?.toString(),
      pinLang: json['pinLang'] != null ? double.tryParse(json['pinLang'].toString()) : null,
      pinLong: json['pinLong'] != null ? double.tryParse(json['pinLong'].toString()) : null,     
       customer: customerModel,
      invoice: invoiceModel,
      invoices: invoicesList,
      invoiceItems: invoiceItemsList,
      trip: tripModel,
      deliveryUpdates: deliveryUpdatesList,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'hasTrip': hasTrip,
      'deliveryNumber': deliveryNumber,
      'customer': customer?.id,
      'invoice': invoice?.id,
      'pinLang': pinLang,
      'pinLong': pinLong,
      'invoices': invoices?.map((invoice) => invoice.id).toList(),
      'invoiceItems':
          invoiceItems?.map((item) => item.id).toList(), // Add this line
      'trip': trip?.id,
      'deliveryUpdates': deliveryUpdates.map((update) => update.id).toList(),
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
    String? deliveryNumber,
    double? pinLang,
    double? pinLong,
    bool? hasTrip,
    DateTime? created,
    DateTime? updated,
  }) {
    return DeliveryDataModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      customer:
          customer ??
          (this.customer is CustomerDataModel
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
      invoice:
          invoice ??
          (this.invoice is InvoiceDataModel
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
      trip:
          trip ??
          (this.trip is TripModel
              ? this.trip as TripModel
              : this.trip != null
              ? TripModel(id: this.trip!.id)
              : null),
      deliveryUpdates:
          deliveryUpdates ??
          (this.deliveryUpdates
              .map(
                (update) =>
                    update is DeliveryUpdateModel
                        ? update
                        : DeliveryUpdateModel(id: update.id),
              )
              .toList()),
      invoiceItems:
          invoiceItems ??
          (this.invoiceItems
              ?.map(
                (item) => // Add this block
                    item is InvoiceItemsModel
                        ? item
                        : InvoiceItemsModel(id: item.id),
              )
              .toList()),
      hasTrip: hasTrip ?? this.hasTrip,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      pinLang: pinLang ?? this.pinLang,
      pinLong: pinLong ?? this.pinLong,
      objectBoxId: objectBoxId,
    );
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
    return 'DeliveryDataModel(id: $id, customer: ${customer?.id}, invoice: ${invoice?.id}, trip: ${trip?.id}, deliveryUpdates: ${deliveryUpdates.length})';
  }
}
