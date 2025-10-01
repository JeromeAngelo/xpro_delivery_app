import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/entity/customer_data_entity.dart';

@Entity()
class InvoiceDataEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? refId;
  final String? name;
  final DateTime? documentDate;
  final double? totalAmount;
  final double? volume;
  final double? weight;
  
  final ToOne<CustomerDataEntity> customer = ToOne<CustomerDataEntity>();
  
  final DateTime? created;
  final DateTime? updated;

  InvoiceDataEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    this.refId,
    this.name,
    this.documentDate,
    this.totalAmount,
    this.volume,
    this.weight,
    CustomerDataEntity? customerData,
    this.created,
    this.updated,
  }) {
    if (customerData != null) customer.target = customerData;
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        refId,
        name,
        documentDate,
        totalAmount,
        volume,
        weight,
        customer.target?.id,
        created,
        updated,
      ];
}
