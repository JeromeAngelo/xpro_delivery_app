import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/entity/invoice_data_entity.dart';

@Entity()
class InvoiceItemsEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? name;
  final String? brand;
  final String? refId;
  final String? uom;
  final double? quantity;
  final double? totalBaseQuantity;
  final double? uomPrice;
  final double? totalAmount;
  
  final ToOne<InvoiceDataEntity> invoiceData = ToOne<InvoiceDataEntity>();
  
  final DateTime? created;
  final DateTime? updated;

  InvoiceItemsEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    this.name,
    this.brand,
    this.refId,
    this.uom,
    this.quantity,
    this.totalBaseQuantity,
    this.uomPrice,
    this.totalAmount,
    InvoiceDataEntity? invoiceData,
    this.created,
    this.updated,
  }) {
    if (invoiceData != null) this.invoiceData.target = invoiceData;
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        name,
        brand,
        refId,
        uom,
        quantity,
        totalBaseQuantity,
        uomPrice,
        totalAmount,
        invoiceData.target?.id,
        created,
        updated,
      ];
}
