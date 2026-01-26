import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';

@Entity()
class DeliveryReceiptEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final ToOne<DeliveryDataModel> deliveryData = ToOne<DeliveryDataModel>();

  final String? status;
  final DateTime? dateTimeCompleted;
  final double? totalAmount;

  // New file fields
  final List<String>? customerImages; // List of image file paths/URLs
  final String? customerSignature; // PDF or image file path/URL for signature
  final String? receiptFile; // PDF file path/URL for receipt

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  DeliveryReceiptEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    TripModel? tripData,
    DeliveryDataModel? deliveryDataModel,
    this.totalAmount,
    this.status,
    this.dateTimeCompleted,
    this.customerImages,
    this.customerSignature,
    this.receiptFile,
    this.created,
    this.updated,
  }) {
    if (tripData != null) trip.target = tripData;
    if (deliveryDataModel != null) deliveryData.target = deliveryDataModel;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    trip.target?.id,
    deliveryData.target?.id,
    status,
    totalAmount,
    dateTimeCompleted,
    customerImages,
    customerSignature,
    receiptFile,
    created,
    updated,
  ];

  @override
  String toString() {
    return 'DeliveryReceiptEntity(id: $id, trip: ${trip.target?.id}, deliveryData: ${deliveryData.target?.id}, status: $status, customerImages: ${customerImages?.length ?? 0}, customerSignature: $customerSignature, receiptFile: $receiptFile)';
  }
}
