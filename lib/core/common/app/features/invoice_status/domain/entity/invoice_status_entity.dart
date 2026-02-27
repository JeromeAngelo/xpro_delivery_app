import 'package:equatable/equatable.dart';

import '../../../Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import '../../../Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';

class InvoiceStatusEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;
  final CustomerDataEntity? customer;
  final InvoiceDataEntity? invoiceData;
    final DeliveryDataEntity? deliveryData;

  final String? tripStatus;
  final DateTime? created;
  final DateTime? updated;

  const InvoiceStatusEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.customer,
    this.invoiceData,
    this.tripStatus,
    this.deliveryData,
    this.created,
    this.updated,
  });
  
  @override
  // TODO: implement props
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        customer,
        invoiceData,
        tripStatus,
        created,
        deliveryData,
        updated
      ];
}
