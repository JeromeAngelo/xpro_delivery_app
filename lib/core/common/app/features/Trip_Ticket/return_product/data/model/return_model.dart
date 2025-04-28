import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class ReturnModel extends ReturnEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  ReturnModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.productName,
    super.productDescription,
    super.reason,
    super.returnDate,
    super.productQuantityCase,
    super.productQuantityPcs,
    super.productQuantityPack,
    super.productQuantityBox,
    super.isCase,
    super.isPcs,
    super.isBox,
    super.isPack,
    super.invoice,
    super.customer,
    super.trip,
  }) : pocketbaseId = id ?? '';

  factory ReturnModel.fromJson(DataMap json) {
    try {
      debugPrint('🔄 Creating ReturnModel from JSON');
      
      // Safely extract expand data
      Map<String, dynamic>? expandedData;
      if (json.containsKey('expand') && json['expand'] != null) {
        if (json['expand'] is Map) {
          // Ensure we have a Map<String, dynamic>
          expandedData = Map<String, dynamic>.from(json['expand'] as Map);
          debugPrint('✅ Successfully extracted expand data');
        } else {
          debugPrint('⚠️ Expand data is not a Map: ${json['expand'].runtimeType}');
        }
      }

      // Process invoice data
      InvoiceModel? invoice;
      if (expandedData != null && expandedData.containsKey('invoice') && expandedData['invoice'] != null) {
        try {
          var invoiceData = expandedData['invoice'];
          debugPrint('🧾 Processing invoice data of type: ${invoiceData.runtimeType}');
          
          if (invoiceData is RecordModel) {
            invoice = InvoiceModel.fromJson({
              'id': invoiceData.id,
              'collectionId': invoiceData.collectionId,
              'collectionName': invoiceData.collectionName,
              ...Map<String, dynamic>.from(invoiceData.data),
            });
          } else if (invoiceData is Map) {
            invoice = InvoiceModel.fromJson(Map<String, dynamic>.from(invoiceData));
          } else {
            debugPrint('⚠️ Unsupported invoice data type: ${invoiceData.runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ Error processing invoice: $e');
        }
      }

      // Process customer data
      CustomerModel? customer;
      if (expandedData != null && expandedData.containsKey('customer') && expandedData['customer'] != null) {
        try {
          var customerData = expandedData['customer'];
          debugPrint('👤 Processing customer data of type: ${customerData.runtimeType}');
          
          if (customerData is RecordModel) {
            customer = CustomerModel.fromJson({
              'id': customerData.id,
              'collectionId': customerData.collectionId,
              'collectionName': customerData.collectionName,
              ...Map<String, dynamic>.from(customerData.data),
            });
          } else if (customerData is Map) {
            customer = CustomerModel.fromJson(Map<String, dynamic>.from(customerData));
          } else {
            debugPrint('⚠️ Unsupported customer data type: ${customerData.runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ Error processing customer: $e');
        }
      }

      // Process trip data
      TripModel? trip;
      if (expandedData != null && expandedData.containsKey('trip') && expandedData['trip'] != null) {
        try {
          var tripData = expandedData['trip'];
          debugPrint('🚚 Processing trip data of type: ${tripData.runtimeType}');
          
          if (tripData is RecordModel) {
            trip = TripModel.fromJson({
              'id': tripData.id,
              'collectionId': tripData.collectionId,
              'collectionName': tripData.collectionName,
              ...Map<String, dynamic>.from(tripData.data),
            });
          } else if (tripData is Map) {
            trip = TripModel.fromJson(Map<String, dynamic>.from(tripData));
          } else {
            debugPrint('⚠️ Unsupported trip data type: ${tripData.runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ Error processing trip: $e');
        }
      }

      // Process return reason
      ProductReturnReason? returnReason;
      if (json['reason'] != null) {
        try {
          returnReason = ProductReturnReason.values.firstWhere(
            (r) => r.toString() == json['reason'],
            orElse: () => ProductReturnReason.damaged,
          );
        } catch (e) {
          debugPrint('⚠️ Error parsing return reason: $e');
          returnReason = ProductReturnReason.damaged;
        }
      }

      // Process return date
      DateTime? returnDate;
      if (json['returnDate'] != null) {
        try {
          returnDate = DateTime.parse(json['returnDate'].toString());
        } catch (e) {
          debugPrint('⚠️ Error parsing return date: $e');
        }
      }

      // Process quantity fields safely
      int? quantityCase, quantityPcs, quantityPack, quantityBox;
      try {
        quantityCase = int.tryParse(json['productQuantityCase']?.toString() ?? '0');
        quantityPcs = int.tryParse(json['productQuantityPcs']?.toString() ?? '0');
        quantityPack = int.tryParse(json['productQuantityPack']?.toString() ?? '0');
        quantityBox = int.tryParse(json['productQuantityBox']?.toString() ?? '0');
      } catch (e) {
        debugPrint('⚠️ Error parsing quantity fields: $e');
      }

      // Process boolean fields safely
      bool? isCase, isPcs, isBox, isPack;
      try {
        isCase = json['isCase'] as bool?;
        isPcs = json['isPcs'] as bool?;
        isBox = json['isBox'] as bool?;
        isPack = json['isPack'] as bool?;
      } catch (e) {
        debugPrint('⚠️ Error parsing boolean fields: $e');
      }

      return ReturnModel(
        id: json['id']?.toString(),
        collectionId: json['collectionId']?.toString(),
        collectionName: json['collectionName']?.toString(),
        productName: json['productName']?.toString(),
        productDescription: json['productDescription']?.toString(),
        productQuantityCase: quantityCase,
        productQuantityPcs: quantityPcs,
        productQuantityPack: quantityPack,
        productQuantityBox: quantityBox,
        isCase: isCase,
        isPcs: isPcs,
        isBox: isBox,
        isPack: isPack,
        reason: returnReason,
        returnDate: returnDate,
        invoice: invoice,
        customer: customer,
        trip: trip,
      );
    } catch (e) {
      debugPrint('❌ Critical error in ReturnModel.fromJson: $e');
      
      // Return a minimal valid model to avoid breaking the app
      return ReturnModel(
        id: json['id']?.toString(),
        productName: json['productName']?.toString() ?? 'Unknown Product',
      );
    }
  }

  DataMap toJson() {
    try {
      return {
        'id': pocketbaseId,
        'collectionId': collectionId,
        'collectionName': collectionName,
        'productName': productName,
        'productDescription': productDescription,
        'productQuantityCase': productQuantityCase,
        'productQuantityPcs': productQuantityPcs,
        'productQuantityPack': productQuantityPack,
        'productQuantityBox': productQuantityBox,
        'isCase': isCase,
        'isPcs': isPcs,
        'isBox': isBox,
        'isPack': isPack,
        'reason': reason?.toString(),
        'returnDate': returnDate?.toIso8601String(),
        'invoice': invoice?.id,  // Just send the ID for relations
        'customer': customer?.id,  // Just send the ID for relations
        'trip': trip?.id,  // Just send the ID for relations
      };
    } catch (e) {
      debugPrint('❌ Error in ReturnModel.toJson: $e');
      // Return minimal valid JSON
      return {
        'id': pocketbaseId,
        'productName': productName ?? 'Unknown Product',
      };
    }
  }
}
