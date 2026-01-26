import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/sync_status_enums.dart';
@Entity()
class DeliveryReceiptModel extends DeliveryReceiptEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  /// 🔑 PocketBase primary ID
  @override
  @Property()
  String? id;

  @Property()
  String pocketbaseId = '';

  @override
  @Property()
  String? collectionId;

  @override
  @Property()
  String? collectionName;

  // ---------------------------------------------------
  // ✅ ObjectBox RELATIONS (SOURCE OF TRUTH)
  // ---------------------------------------------------

  final trip = ToOne<TripModel>();
  final deliveryData = ToOne<DeliveryDataModel>();

  // ---------------------------------------------------
  // Business fields
  // ---------------------------------------------------

  // Stored as CSV due to ObjectBox limitation
  @Property()
  String? customerImagesString;

  @Property()
  double? totalAmount;

  @Property()
  String? status;

  @Property()
  DateTime? dateTimeCompleted;

  @Property()
  String? customerSignature;

  @Property()
  String? receiptFile;

  // ---------------------------------------------------
  // Sync & audit fields
  // ---------------------------------------------------

  @Property()
  DateTime? created;

  @Property()
  DateTime? updated;

  @Property()
  DateTime? lastLocalUpdatedAt;

  @Property()
  String syncStatus = SyncStatus.synced.name;

  @Property()
  int retryCount = 0;

  @Property()
  DateTime? lastSyncAttemptAt;

  @Property()
  DateTime? nextRetryAt;

  @Property()
  String? lastSyncError;

  @Property()
  int version = 0;

  @Property()
  String? updatedBy;

  @Property()
  String? deviceId;

  // ---------------------------------------------------
  // Constructor
  // ---------------------------------------------------
  DeliveryReceiptModel({
    super.dbId,
    super.id,
    super.collectionId,
    super.collectionName,
    TripModel? tripModel,
    DeliveryDataModel? deliveryDataModel,
    super.status,
    super.dateTimeCompleted,
    super.customerImages,
    super.customerSignature,
    super.totalAmount,
    super.receiptFile,
    super.created,
    super.updated,
    this.objectBoxId = 0,
  }) : pocketbaseId = id ?? '' {
    if (tripModel != null) {
      trip.target = tripModel;
    }

    if (deliveryDataModel != null) {
      deliveryData.target = deliveryDataModel;
    }

    customerImagesString = customerImages?.join(',');
  }

  // ---------------------------------------------------
  // Helpers
  // ---------------------------------------------------

  // List<String>? get customerImages =>
  //     customerImagesString?.split(',').where((e) => e.isNotEmpty).toList();

  // ---------------------------------------------------
  // JSON → MODEL (SYNC SAFE)
  // ---------------------------------------------------
  factory DeliveryReceiptModel.fromJson(DataMap json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    List<String>? parseCustomerImages(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String && value.isNotEmpty) {
        return value.split(',').where((s) => s.trim().isNotEmpty).toList();
      }
      return null;
    }

    final expanded = json['expand'] as Map<String, dynamic>?;

    TripModel? tripModel;
    DeliveryDataModel? deliveryDataModel;

    if (expanded?['trip'] != null) {
      final t = expanded!['trip'];
      tripModel =
          t is RecordModel
              ? TripModel.fromJson({
                'id': t.id,
                'collectionId': t.collectionId,
                'collectionName': t.collectionName,
                ...t.data,
                'expand': t.expand,
              })
              : TripModel.fromJson(t as DataMap);
    }

    if (expanded?['deliveryData'] != null) {
      final d = expanded!['deliveryData'];
      deliveryDataModel =
          d is RecordModel
              ? DeliveryDataModel.fromJson({
                'id': d.id,
                'collectionId': d.collectionId,
                'collectionName': d.collectionName,
                ...d.data,
                'expand': d.expand,
              })
              : DeliveryDataModel.fromJson(d as DataMap);
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
      totalAmount:
          json['totalAmount'] != null
              ? double.tryParse(json['totalAmount'].toString())
              : null,
      tripModel: tripModel,
      deliveryDataModel: deliveryDataModel,
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
    return customerImagesString!
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
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
