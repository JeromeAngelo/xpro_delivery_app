import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

@Entity()
class InvoiceModel extends InvoiceEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? customerId;

  @Property()
  String? tripId;

  InvoiceModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.invoiceNumber,
    super.productsList,
    super.status,
    super.customer,
    super.trip,
    super.totalAmount,
    super.confirmTotalAmount,
    super.customerDeliveryStatus,
    super.created,
    super.updated,
    this.customerId,
    super.isCompleted,
    this.tripId,
  }) : pocketbaseId = id ?? '';
  // Update the fromJson method in InvoiceModel
  factory InvoiceModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

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
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
      }
    }

    // Handle customer data
    final customerData = expandedData?['customer'];
    CustomerModel? customerModel;
    if (customerData != null) {
      if (customerData is RecordModel) {
        customerModel = CustomerModel.fromJson({
          'id': customerData.id,
          'collectionId': customerData.collectionId,
          'collectionName': customerData.collectionName,
          ...customerData.data,
        });
      } else if (customerData is Map) {
        customerModel = CustomerModel.fromJson(
          customerData as Map<String, dynamic>,
        );
      }
    }

    // Handle products with detailed logging
    debugPrint('📦 Processing products data');
    final productsList =
        (json['productsList'] as List?)?.map((product) {
          debugPrint('   🏷️ Product data: $product');
          if (product is RecordModel) {
            return ProductModel.fromJson({
              'id': product.id,
              'collectionId': product.collectionId,
              'collectionName': product.collectionName,
              ...product.data,
            });
          }
          return ProductModel.fromJson(product as DataMap);
        }).toList() ??
        [];
    debugPrint('✅ Mapped ${productsList.length} products');

    return InvoiceModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
     isCompleted: json['isCompleted'] as bool? ?? false,
      productsList: productsList,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'truck'),
        orElse: () => InvoiceStatus.truck,
      ),
      customer: customerModel,
      customerId: json['customer']?.toString(),
      tripId: json['trip']?.toString(),
      trip: tripModel,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0.0'),
      confirmTotalAmount: double.tryParse(
        json['confirmTotalAmount']?.toString() ?? '0.0',
      ),
      customerDeliveryStatus: json['customerDeliveryStatus']?.toString(),
      created:
          json['created'] != null
              ? DateTime.parse(json['created'].toString())
              : null,
      updated:
          json['updated'] != null
              ? DateTime.parse(json['updated'].toString())
              : null,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'invoiceNumber': invoiceNumber,
      'productsList': productList.map((product) => product.toJson()).toList(),
      'status': status?.toString().split('.').last,
      'customer': customerId,
      'trip': tripId,
      'totalAmount': totalAmount,
      'isCompleted': isCompleted,
      'confirmTotalAmount': confirmTotalAmount,
      'customerDeliveryStatus': customerDeliveryStatus,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? invoiceNumber,
    List<ProductModel>? productsList,
    InvoiceStatus? status,
    CustomerModel? customer,
    String? customerId,
    TripModel? trip,
    String? tripId,
    double? totalAmount,
    double? confirmTotalAmount,
    String? customerDeliveryStatus,
    DateTime? created,
    DateTime? updated,
    bool? isCompleted,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      productsList: productsList ?? this.productList.toList(),
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      customer: customer ?? this.customer.target,
      customerId: customerId ?? this.customerId,
      trip: trip ?? this.trip.target,
      tripId: tripId ?? this.tripId,
      totalAmount: totalAmount ?? this.totalAmount,
      confirmTotalAmount: confirmTotalAmount ?? this.confirmTotalAmount,
      customerDeliveryStatus:
          customerDeliveryStatus ?? this.customerDeliveryStatus,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
