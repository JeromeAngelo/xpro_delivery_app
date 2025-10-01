import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class DeliveryReceiptModel extends DeliveryReceiptEntity {
  @Id()
  int objectBoxId = 0;
  
  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  @Property()
  String? deliveryDataId;

  // ObjectBox doesn't support List<String> directly, so we store as comma-separated string
  @Property()
  String? customerImagesString;

  DeliveryReceiptModel({
    super.dbId = 0,
    super.id,
    super.collectionId,
    super.collectionName,
    TripModel? trip,
    DeliveryDataModel? deliveryData,
    super.status,
    super.dateTimeCompleted,
    super.customerImages,
    super.customerSignature,
    super.totalAmount,
    super.receiptFile,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : 
    pocketbaseId = id ?? '',
    tripId = trip?.id,
    deliveryDataId = deliveryData?.id,
    customerImagesString = customerImages?.join(','),
    super(
      tripData: trip,
      deliveryDataModel: deliveryData,
    );

  factory DeliveryReceiptModel.fromJson(DataMap json) {
    // Add safe date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Parse customer images list
    List<String>? parseCustomerImages(dynamic value) {
      if (value == null) return null;
      
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String && value.isNotEmpty) {
        // Handle comma-separated string format
        return value.split(',').where((s) => s.trim().isNotEmpty).toList();
      }
      
      return null;
    }

    // Handle expanded data for relations
    final expandedData = json['expand'] as Map<String, dynamic>?;
    
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

    return DeliveryReceiptModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      status: json['status']?.toString(),
      dateTimeCompleted: parseDate(json['dateTimeCompleted']),
      customerImages: parseCustomerImages(json['customerImages']),
      customerSignature: json['customerSignature']?.toString(),
      receiptFile: json['receiptFile']?.toString(),
      totalAmount: json['totalAmount']!= null ? double.tryParse(json['totalAmount'].toString()) : null,
      trip: tripModel,
      deliveryData: deliveryDataModel,
      created: parseDate(json['created']),
      updated: parseDate(json['updated']),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'status': status,
      'totalAmount': totalAmount,
      'dateTimeCompleted': dateTimeCompleted?.toIso8601String(),
      'customerImages': customerImages, // Will be serialized as JSON array
      'customerSignature': customerSignature,
      'receiptFile': receiptFile,
      'trip': trip.target?.id,
      'deliveryData': deliveryData.target?.id,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  DeliveryReceiptModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    TripModel? trip,
    DeliveryDataModel? deliveryData,
    double? totalAmount,
    String? status,
    DateTime? dateTimeCompleted,
    List<String>? customerImages,
    String? customerSignature,
    String? receiptFile,
    DateTime? created,
    DateTime? updated,
  }) {
    final model = DeliveryReceiptModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      status: status ?? this.status,
      dateTimeCompleted: dateTimeCompleted ?? this.dateTimeCompleted,
      totalAmount: totalAmount ?? this.totalAmount,
      customerImages: customerImages ?? this.customerImages,
      customerSignature: customerSignature ?? this.customerSignature,
      receiptFile: receiptFile ?? this.receiptFile,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      objectBoxId: objectBoxId,
    );
    
    // Handle relations
    if (trip != null) {
      model.trip.target = trip;
    } else if (this.trip.target != null) {
      model.trip.target = this.trip.target;
    }
    
    if (deliveryData != null) {
      model.deliveryData.target = deliveryData;
    } else if (this.deliveryData.target != null) {
      model.deliveryData.target = this.deliveryData.target;
    }
    
    return model;
  }

  // Helper getter to access customerImages as List<String>
  @override
  List<String>? get customerImages {
    if (customerImagesString == null || customerImagesString!.isEmpty) {
      return super.customerImages;
    }
    return customerImagesString!.split(',').where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryReceiptModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeliveryReceiptModel(id: $id, trip: ${trip.target?.id}, deliveryData: ${deliveryData.target?.id}, status: $status, dateTimeCompleted: $dateTimeCompleted, customerImages: ${customerImages?.length ?? 0}, customerSignature: $customerSignature, receiptFile: $receiptFile)';
  }
}
