import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

@Entity()
class InvoiceStatusEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  final String? collectionId;
  final String? collectionName;

  // Relations
  final ToOne<InvoiceDataModel> invoiceData = ToOne<InvoiceDataModel>();

  final InvoiceStatus? tripStatus;

  // Standard fields
  final DateTime? created;
  final DateTime? updated;

  InvoiceStatusEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    InvoiceDataModel? invoiceDataModel,
    this.tripStatus,
    this.created,
    this.updated,
  }) {
    if (invoiceDataModel != null) invoiceData.target = invoiceDataModel;
  }

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    invoiceData.target?.id,
    tripStatus,
    created,
    updated,
  ];
}
