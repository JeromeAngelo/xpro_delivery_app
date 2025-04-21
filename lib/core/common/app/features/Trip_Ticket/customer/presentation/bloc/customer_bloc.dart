import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/calculate_customer_total_time.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/get_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/get_customersLocation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final InvoiceBloc _invoiceBloc;
  final DeliveryUpdateBloc _deliveryUpdateBloc;
  final GetCustomer _getCustomer;
  final GetCustomersLocation _getCustomersLocation;
  final CalculateCustomerTotalTime _calculateCustomerTotalTime;

  CustomerState? _cachedState;

  CustomerBloc({
    required InvoiceBloc invoiceBloc,
    required DeliveryUpdateBloc deliveryUpdateBloc,
    required GetCustomer getCustomer,
    required GetCustomersLocation getCustomersLocation,
    required CalculateCustomerTotalTime calculateCustomerTotalTime,
  })  : _invoiceBloc = invoiceBloc,
        _deliveryUpdateBloc = deliveryUpdateBloc,
        _getCustomer = getCustomer,
        _getCustomersLocation = getCustomersLocation,
        _calculateCustomerTotalTime = calculateCustomerTotalTime,
        super(CustomerInitial()) {
    on<GetCustomerEvent>(_onGetCustomer);
    on<GetCustomerLocationEvent>(_onGetCustomerLocation);
    on<LoadLocalCustomersEvent>(_onLoadLocalCustomers);
    on<LoadLocalCustomerLocationEvent>(_onLoadLocalCustomerLocation);
    on<CalculateCustomerTotalTimeEvent>(
        _onCalculateCustomerTotalTime); // Add this line
  }

  Future<void> _onCalculateCustomerTotalTime(
    CalculateCustomerTotalTimeEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await _calculateCustomerTotalTime(event.customerId);

    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (totalTime) => emit(CustomerTotalTimeCalculated(
        totalTime: totalTime,
        customerId: event.customerId,
      )),
    );
  }

  Future<void> _onGetCustomer(
      GetCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    debugPrint('🌐 Fetching customers from remote');

    final result = await _getCustomer(event.tripId);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) {
        _invoiceBloc.add(const GetInvoiceEvent());
        if (customers.isNotEmpty) {
          _deliveryUpdateBloc
              .add(GetDeliveryStatusChoicesEvent(customers.first.id ?? ''));
        }
        final newState = CustomerLoaded(
          customer: customers,
          invoice: _invoiceBloc.state,
          deliveryUpdate: _deliveryUpdateBloc.state,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetCustomerLocation(
      GetCustomerLocationEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLocationLoading());
    debugPrint('🌐 Fetching customer location from remote');

    final result = await _getCustomersLocation(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) {
        debugPrint(
            '📍 Customer location loaded: ${customer.latitude}, ${customer.longitude}');
        emit(CustomerLocationLoaded(customer));
      },
    );
  }

  Future<void> _onLoadLocalCustomers(
      LoadLocalCustomersEvent event, Emitter<CustomerState> emit) async {
    debugPrint('📱 Loading local customers');
    final result = await _getCustomer.loadFromLocal(event.tripId);

    await result.fold(
      (failure) async =>
          emit(CustomerError(failure.message, isLocalError: true)),
      (localCustomers) async {
        emit(CustomerLoaded(
          customer: localCustomers,
          invoice: _invoiceBloc.state,
          deliveryUpdate: _deliveryUpdateBloc.state,
          isFromLocal: true,
        ));
        debugPrint(
            '✅ Loaded ${localCustomers.length} customers from local storage');
      },
    );
  }
Future<void> _onLoadLocalCustomerLocation(
  LoadLocalCustomerLocationEvent event,
  Emitter<CustomerState> emit,
) async {
  debugPrint('📱 Loading local customer location');
  emit(CustomerLocationLoading());

  final result = await _getCustomersLocation.loadFromLocal(event.customerId);

  await result.fold(
    (failure) async => emit(CustomerError(failure.message, isLocalError: true)),
    (localCustomer) async {
      emit(CustomerLocationLoaded(localCustomer, isFromLocal: true));
      debugPrint('✅ Loaded location data for customer: ${localCustomer.id}');
      debugPrint('   📍 Location: ${localCustomer.latitude}, ${localCustomer.longitude}');
      debugPrint('   🏪 Store: ${localCustomer.storeName}');
    },
  );
}


}
