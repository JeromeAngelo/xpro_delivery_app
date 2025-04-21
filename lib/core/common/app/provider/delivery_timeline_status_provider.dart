import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';

class DeliveryStatusProvider extends ChangeNotifier {
  final DeliveryUpdateBloc deliveryUpdateBloc;
  String? currentCustomerId;
  
  DeliveryStatusProvider({required this.deliveryUpdateBloc});

  List<DeliveryUpdateEntity> _availableStatuses = [];
  String _currentStatus = '';
  
  List<DeliveryUpdateEntity> get availableStatuses => _availableStatuses;
  String get currentStatus => _currentStatus;

  void loadInitialData(String customerId) {
    currentCustomerId = customerId;
    deliveryUpdateBloc.add(GetDeliveryStatusChoicesEvent(customerId));
  }

  void updateDeliveryStatus(String customerId, String statusId) {
    deliveryUpdateBloc.add(UpdateDeliveryStatusEvent(
      customerId: customerId,
      statusId: statusId,
    ));
    notifyListeners();
  }

  void setAvailableStatuses(List<DeliveryUpdateEntity> statuses) {
    _availableStatuses = statuses;
    notifyListeners();
  }

  void setCurrentStatus(String status) {
    _currentStatus = status;
    notifyListeners();
  }
}
