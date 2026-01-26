import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';

@Entity()
class DeliveryUpdateEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? title;
  String? subtitle;
  DateTime? time;
  DateTime? created;
  DateTime? updated;
  String? customer;
  String? image;
  bool? isAssigned;
  String? assignedTo;
  String? remarks;
  // Added deliveryData relation
  final ToOne<DeliveryDataModel> deliveryData = ToOne<DeliveryDataModel>();

  DeliveryUpdateEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.title,
    this.subtitle,
    this.time,
    this.created,
    this.updated,
    this.customer,
    this.remarks,
    this.image,
    this.isAssigned,
    this.assignedTo,
    DeliveryDataModel? deliveryData,
  }) {
   
    // Initialize deliveryData relation
    if (deliveryData != null) {
      this.deliveryData.target = deliveryData;
    }
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        title,
        subtitle,
        time,
        created,
        updated,
        remarks,
        customer,
        isAssigned,
        assignedTo,
        image,
        deliveryData.target?.id,
      ];
}
