import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
abstract class DeliveryUpdateEvent extends Equatable {
  const DeliveryUpdateEvent();
}

class GetDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final String customerId;
  const GetDeliveryStatusChoicesEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

class LoadLocalDeliveryStatusChoicesEvent extends DeliveryUpdateEvent {
  final String customerId;
  const LoadLocalDeliveryStatusChoicesEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

// Existing events remain the same
class UpdateDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String customerId;
  final String statusId;
  const UpdateDeliveryStatusEvent({required this.customerId, required this.statusId});
  @override
  List<Object> get props => [customerId, statusId];
}

class CompleteDeliveryEvent extends DeliveryUpdateEvent {
  final String customerId;
  final List<InvoiceModel> invoices;
  final List<TransactionModel> transactions;
  final List<ReturnModel> returns;
  final List<DeliveryUpdateModel> deliveryStatus;
  const CompleteDeliveryEvent({
    required this.customerId,
    required this.invoices,
    required this.transactions,
    required this.returns,
    required this.deliveryStatus,
  });
  @override
  List<Object> get props => [customerId, invoices, transactions, returns, deliveryStatus];
}

class CheckEndDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String tripId;
  
  const CheckEndDeliveryStatusEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class CheckLocalEndDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String tripId;
  
  const CheckLocalEndDeliveryStatusEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}


class InitializePendingStatusEvent extends DeliveryUpdateEvent {
  final List<String> customerIds;
  const InitializePendingStatusEvent(this.customerIds);
  @override
  List<Object> get props => [customerIds];
}

class CreateDeliveryStatusEvent extends DeliveryUpdateEvent {
  final String customerId;
  final String title;
  final String subtitle;
  final DateTime time;
  final bool isAssigned;
  final String image;
  const CreateDeliveryStatusEvent({
    required this.customerId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isAssigned,
    required this.image,
  });
  @override
  List<Object> get props => [customerId, title, subtitle, time, isAssigned, image];
}
class UpdateQueueRemarksEvent extends DeliveryUpdateEvent {
  final String customerId;
  final String queueCount;

  const UpdateQueueRemarksEvent({
    required this.customerId,
    required this.queueCount,
  });

  @override
  List<Object> get props => [customerId,  queueCount];
}
