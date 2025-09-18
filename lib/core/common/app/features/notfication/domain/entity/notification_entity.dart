import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/enums/notification_type_enum.dart';

import '../../../Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';

class NotificationEntity extends Equatable {
  String? id;
  DeliveryUpdateModel? status;
  DeliveryDataModel? delivery;
  TripModel? trip;
  String? body;
  DateTime? createdAt;
  bool? isRead;
  NotificationTypeEnum? type;

  NotificationEntity({
    this.id,
    this.status,
    this.delivery,
    this.trip,
    this.body,
    this.createdAt,
    this.isRead,
    this.type,
  });

  @override
  List<Object?> get props => [
    id,
    status,
    delivery,
    trip,
    createdAt,
    body,
    isRead,
    type,
  ];
}
