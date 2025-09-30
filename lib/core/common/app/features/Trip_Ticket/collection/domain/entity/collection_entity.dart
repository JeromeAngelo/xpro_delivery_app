import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart'
    show InvoiceDataEntity;

import '../../../trip/domain/entity/trip_entity.dart';
import '../../../customer_data/domain/entity/customer_data_entity.dart';
import '../../../delivery_data/domain/entity/delivery_data_entity.dart';

class CollectionEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations - using entities instead of models
  final DeliveryDataEntity? deliveryData;
  final TripEntity? trip;
  final CustomerDataEntity? customer;
  final InvoiceDataEntity? invoice;

  final List<InvoiceDataEntity>? invoices;

  final String? status;

  final double? totalAmount;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  const CollectionEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.deliveryData,
    this.trip,
    this.status,
    this.customer,
    this.invoices,
    this.invoice,
    this.totalAmount,
    this.created,
    this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    deliveryData?.id,
    trip?.id,
    customer?.id,
    invoice?.id,
    totalAmount,
    status,
    created,
    updated,
  ];

  // Factory constructor for creating an empty entity
  factory CollectionEntity.empty() {
    return const CollectionEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      deliveryData: null,
      trip: null,
      customer: null,
      status: '',
      invoice: null,
      totalAmount: 0.0,
      created: null,
      updated: null,
    );
  }

  // CopyWith method for immutable updates
  CollectionEntity copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryDataEntity? deliveryData,
    TripEntity? trip,
    CustomerDataEntity? customer,
    InvoiceDataEntity? invoice,
    String? status,
    double? totalAmount,
    DateTime? created,
    DateTime? updated,
  }) {
    return CollectionEntity(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      deliveryData: deliveryData ?? this.deliveryData,
      trip: trip ?? this.trip,
      customer: customer ?? this.customer,
      invoice: invoice ?? this.invoice,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'CollectionEntity('
        'id: $id, '
        'collectionId: $collectionId, '
        'collectionName: $collectionName, '
        'deliveryData: ${deliveryData?.id}, '
        'trip: ${trip?.id}, '
        'customer: ${customer?.id}, '
        'invoice: ${invoice?.id}, '
        'totalAmount: $totalAmount, '
        'created: $created, '
        'status: $status, '
        'updated: $updated'
        ')';
  }
}
