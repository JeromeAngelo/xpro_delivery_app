import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/add_customer_to_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/create_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/delete_all_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/delete_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/get_all_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/get_customer_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/get_customer_data_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/usecases/update_customer_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/presentation/bloc/customer_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/presentation/bloc/customer_data_state.dart';


class CustomerDataBloc extends Bloc<CustomerDataEvent, CustomerDataState> {
  final GetAllCustomerData _getAllCustomerData;
  final GetCustomerDataById _getCustomerDataById;
  final CreateCustomerData _createCustomerData;
  final UpdateCustomerData _updateCustomerData;
  final DeleteCustomerData _deleteCustomerData;
  final DeleteAllCustomerData _deleteAllCustomerData;
  final AddCustomerToDelivery _addCustomerToDelivery;
  final GetCustomersByDeliveryId _getCustomersByDeliveryId;

  CustomerDataState? _cachedState;

  CustomerDataBloc({
    required GetAllCustomerData getAllCustomerData,
    required GetCustomerDataById getCustomerDataById,
    required CreateCustomerData createCustomerData,
    required UpdateCustomerData updateCustomerData,
    required DeleteCustomerData deleteCustomerData,
    required DeleteAllCustomerData deleteAllCustomerData,
    required AddCustomerToDelivery addCustomerToDelivery,
    required GetCustomersByDeliveryId getCustomersByDeliveryId,
  })  : _getAllCustomerData = getAllCustomerData,
        _getCustomerDataById = getCustomerDataById,
        _createCustomerData = createCustomerData,
        _updateCustomerData = updateCustomerData,
        _deleteCustomerData = deleteCustomerData,
        _deleteAllCustomerData = deleteAllCustomerData,
        _addCustomerToDelivery = addCustomerToDelivery,
        _getCustomersByDeliveryId = getCustomersByDeliveryId,
        super(const CustomerDataInitial()) {
    on<GetAllCustomerDataEvent>(_onGetAllCustomerData);
    on<GetCustomerDataByIdEvent>(_onGetCustomerDataById);
    on<CreateCustomerDataEvent>(_onCreateCustomerData);
    on<UpdateCustomerDataEvent>(_onUpdateCustomerData);
    on<DeleteCustomerDataEvent>(_onDeleteCustomerData);
    on<DeleteAllCustomerDataEvent>(_onDeleteAllCustomerData);
    on<AddCustomerToDeliveryEvent>(_onAddCustomerToDelivery);
    on<GetCustomersByDeliveryIdEvent>(_onGetCustomersByDeliveryId);
  }

  Future<void> _onGetAllCustomerData(
    GetAllCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Getting all customer data');

    final result = await _getAllCustomerData();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get all customer data: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (customerData) {
        debugPrint('✅ Retrieved ${customerData.length} customer data records');
        final newState = AllCustomerDataLoaded(customerData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetCustomerDataById(
    GetCustomerDataByIdEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Getting customer data by ID: ${event.id}');

    final result = await _getCustomerDataById(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get customer data: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (customerData) {
        debugPrint('✅ Retrieved customer data: ${customerData.id}');
        final newState = CustomerDataLoaded(customerData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onCreateCustomerData(
    CreateCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Creating new customer data');

    final result = await _createCustomerData(
      CreateCustomerDataParams(
        name: event.name,
        refId: event.refId,
        province: event.province,
        municipality: event.municipality,
        barangay: event.barangay,
        longitude: event.longitude,
        latitude: event.latitude,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Failed to create customer data: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (customerData) {
        debugPrint('✅ Successfully created customer data: ${customerData.id}');
        emit(CustomerDataCreated(customerData));
        
        // Refresh the customer data list
        add(const GetAllCustomerDataEvent());
      },
    );
  }

  Future<void> _onUpdateCustomerData(
    UpdateCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Updating customer data: ${event.id}');

    final result = await _updateCustomerData(
      UpdateCustomerDataParams(
        id: event.id,
        name: event.name,
        refId: event.refId,
        province: event.province,
        municipality: event.municipality,
        barangay: event.barangay,
        longitude: event.longitude,
        latitude: event.latitude,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Failed to update customer data: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (customerData) {
        debugPrint('✅ Successfully updated customer data: ${customerData.id}');
        emit(CustomerDataUpdated(customerData));
        
        // Refresh the customer data
        add(GetCustomerDataByIdEvent(customerData.id!));
      },
    );
  }

  Future<void> _onDeleteCustomerData(
    DeleteCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Deleting customer data: ${event.id}');

    final result = await _deleteCustomerData(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to delete customer data: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (_) {
        debugPrint('✅ Successfully deleted customer data');
        emit(CustomerDataDeleted(event.id));
        
        // Refresh the customer data list
        add(const GetAllCustomerDataEvent());
      },
    );
  }

  Future<void> _onDeleteAllCustomerData(
    DeleteAllCustomerDataEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Deleting multiple customer data records: ${event.ids.length} items');

    final result = await _deleteAllCustomerData(event.ids);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to delete customer data records: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (_) {
        debugPrint('✅ Successfully deleted all customer data records');
        emit(AllCustomerDataDeleted(event.ids));
        
        // Refresh the customer data list
        add(const GetAllCustomerDataEvent());
      },
    );
  }

  Future<void> _onAddCustomerToDelivery(
    AddCustomerToDeliveryEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Adding customer ${event.customerId} to delivery ${event.deliveryId}');

    final result = await _addCustomerToDelivery(
      AddCustomerToDeliveryParams(
        customerId: event.customerId,
        deliveryId: event.deliveryId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Failed to add customer to delivery: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (_) {
        debugPrint('✅ Successfully added customer to delivery');
        emit(CustomerAddedToDelivery(
          customerId: event.customerId,
          deliveryId: event.deliveryId,
        ));
        
        // Refresh the customers for this delivery
        add(GetCustomersByDeliveryIdEvent(event.deliveryId));
      },
    );
  }

  Future<void> _onGetCustomersByDeliveryId(
    GetCustomersByDeliveryIdEvent event,
    Emitter<CustomerDataState> emit,
  ) async {
    emit(const CustomerDataLoading());
    debugPrint('🔄 Getting customers for delivery: ${event.deliveryId}');

    final result = await _getCustomersByDeliveryId(event.deliveryId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get customers by delivery ID: ${failure.message}');
        emit(CustomerDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (customers) {
        debugPrint('✅ Retrieved ${customers.length} customers for delivery');
        final newState = CustomersByDeliveryLoaded(
          customers: customers,
          deliveryId: event.deliveryId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
