import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';

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
  final ToMany<CustomerModel> customers = ToMany<CustomerModel>();

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
    List<CustomerModel>? customersList,
  }) {
    if (customersList != null) {
      customers.addAll(customersList);
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
        customers,
        image,
      ];
}
