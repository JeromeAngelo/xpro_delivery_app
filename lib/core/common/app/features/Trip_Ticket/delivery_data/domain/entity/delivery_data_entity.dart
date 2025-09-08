import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';

import '../../../invoice_items/domain/entity/invoice_items_entity.dart';

class DeliveryDataEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final CustomerDataEntity? customer;
  final InvoiceDataEntity? invoice;
  final TripEntity? trip;
  final List<InvoiceDataEntity>? invoices; // List of invoice updates>
  final List<DeliveryUpdateEntity> deliveryUpdates;
  final List<InvoiceItemsEntity>? invoiceItems;
  final String? deliveryNumber;
  final double? pinLang;
  final double? pinLong;
  // Standard fields
  final DateTime? created;
  final DateTime? updated;
  final bool? hasTrip;

  const DeliveryDataEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.customer,
    this.invoice,
    this.deliveryNumber,
    this.pinLang,
    this.pinLong,
    this.invoices,
    this.invoiceItems,
    this.trip,
    this.deliveryUpdates = const [],
    this.created,
    this.updated,
    this.hasTrip,
  });

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    customer,
    invoice,
    deliveryNumber,
    invoiceItems,
    invoices,
    trip,
    deliveryUpdates,
    hasTrip,
    created,
    updated,
  ];
}
