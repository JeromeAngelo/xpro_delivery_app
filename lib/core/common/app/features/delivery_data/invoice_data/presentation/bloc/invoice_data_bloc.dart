
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/add_invoice_data_to_delivery.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/add_invoice_data_to_invoice_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/get_all_invoice_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/get_invoice_data_by_customer_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/get_invoice_data_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/get_invoice_data_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/usecase/set_invoice_unloaded.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/presentation/bloc/invoice_data_state.dart';

class InvoiceDataBloc extends Bloc<InvoiceDataEvent, InvoiceDataState> {
  final GetAllInvoiceData _getAllInvoiceData;
  final GetInvoiceDataById _getInvoiceDataById;
  final GetInvoiceDataByDeliveryId _getInvoiceDataByDeliveryId;
  final GetInvoiceDataByCustomerId _getInvoiceDataByCustomerId;
  final AddInvoiceDataToDelivery _addInvoiceDataToDelivery;
  final AddInvoiceDataToInvoiceStatus _addInvoiceDataToInvoiceStatus;
  final SetInvoiceUnloaded _setInvoiceUnloaded;

  InvoiceDataState? _cachedState;

  InvoiceDataBloc({
    required GetAllInvoiceData getAllInvoiceData,
    required GetInvoiceDataById getInvoiceDataById,
    required GetInvoiceDataByDeliveryId getInvoiceDataByDeliveryId,
    required GetInvoiceDataByCustomerId getInvoiceDataByCustomerId,
    required AddInvoiceDataToDelivery addInvoiceDataToDelivery,
    required AddInvoiceDataToInvoiceStatus addInvoiceDataToInvoiceStatus,
    required SetInvoiceUnloaded setInvoiceUnloaded,
  })  : _getAllInvoiceData = getAllInvoiceData,
        _getInvoiceDataById = getInvoiceDataById,
        _getInvoiceDataByDeliveryId = getInvoiceDataByDeliveryId,
        _getInvoiceDataByCustomerId = getInvoiceDataByCustomerId,
        _addInvoiceDataToDelivery = addInvoiceDataToDelivery,
        _addInvoiceDataToInvoiceStatus = addInvoiceDataToInvoiceStatus,
        _setInvoiceUnloaded = setInvoiceUnloaded,
        super(const InvoiceDataInitial()) {
    on<GetAllInvoiceDataEvent>(_onGetAllInvoiceData);
    on<GetInvoiceDataByIdEvent>(_onGetInvoiceDataById);
    on<GetInvoiceDataByDeliveryIdEvent>(_onGetInvoiceDataByDeliveryId);
    on<GetInvoiceDataByCustomerIdEvent>(_onGetInvoiceDataByCustomerId);
    on<AddInvoiceDataToDeliveryEvent>(_onAddInvoiceDataToDelivery);
    on<AddInvoiceDataToInvoiceStatusEvent>(_onAddInvoiceDataToInvoiceStatus);
    on<SetInvoiceUnloadedByIdEvent>(_onSetInvoiceUnloadedById);
  }

  Future<void> _onGetAllInvoiceData(
    GetAllInvoiceDataEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Getting all invoice data');

    final result = await _getAllInvoiceData();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get all invoice data: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceData) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceData.length} invoice data records');
        final newState = AllInvoiceDataLoaded(invoiceData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetInvoiceDataById(
    GetInvoiceDataByIdEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Getting invoice data by ID: ${event.id}');

    final result = await _getInvoiceDataById(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get invoice data: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceData) {
        debugPrint('✅ BLOC: Successfully retrieved invoice data: ${invoiceData.id}');
        final newState = InvoiceDataLoaded(invoiceData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetInvoiceDataByDeliveryId(
    GetInvoiceDataByDeliveryIdEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Getting invoice data for delivery: ${event.deliveryId}');

    final result = await _getInvoiceDataByDeliveryId(event.deliveryId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get invoice data by delivery ID: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceData) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceData.length} invoices for delivery');
        final newState = InvoiceDataByDeliveryLoaded(
          invoiceData: invoiceData,
          deliveryId: event.deliveryId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetInvoiceDataByCustomerId(
    GetInvoiceDataByCustomerIdEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Getting invoice data for customer: ${event.customerId}');

    final result = await _getInvoiceDataByCustomerId(event.customerId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get invoice data by customer ID: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceData) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceData.length} invoices for customer');
        final newState = InvoiceDataByCustomerLoaded(
          invoiceData: invoiceData,
          customerId: event.customerId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onAddInvoiceDataToDelivery(
    AddInvoiceDataToDeliveryEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Adding invoice ${event.invoiceId} to delivery ${event.deliveryId}');

    final result = await _addInvoiceDataToDelivery(
      AddInvoiceDataToDeliveryParams(
        invoiceId: event.invoiceId,
        deliveryId: event.deliveryId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to add invoice to delivery: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (_) {
        debugPrint('✅ BLOC: Successfully added invoice to delivery');
        emit(InvoiceDataAddedToDelivery(
          invoiceId: event.invoiceId,
          deliveryId: event.deliveryId,
        ));
        
        // Refresh the invoices for this delivery
        add(GetInvoiceDataByDeliveryIdEvent(event.deliveryId));
      },
    );
  }

  Future<void> _onAddInvoiceDataToInvoiceStatus(
    AddInvoiceDataToInvoiceStatusEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Adding invoice ${event.invoiceId} to invoice status ${event.invoiceStatusId}');

    final result = await _addInvoiceDataToInvoiceStatus(
      AddInvoiceDataToInvoiceStatusParams(
        invoiceId: event.invoiceId,
        invoiceStatusId: event.invoiceStatusId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to add invoice to invoice status: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (_) {
        debugPrint('✅ BLOC: Successfully added invoice to invoice status');
        emit(InvoiceDataAddedToInvoiceStatus(
          invoiceId: event.invoiceId,
          invoiceStatusId: event.invoiceStatusId,
        ));
        
        // Refresh the invoice data
        add(GetInvoiceDataByIdEvent(event.invoiceId));
      },
    );
  }

  Future<void> _onSetInvoiceUnloadedById(
    SetInvoiceUnloadedByIdEvent event,
    Emitter<InvoiceDataState> emit,
  ) async {
    emit(const InvoiceDataLoading());
    debugPrint('🔄 BLOC: Setting invoice to unloaded: ${event.invoiceDataId}');

    final result = await _setInvoiceUnloaded(event.invoiceDataId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to set invoice to unloaded: ${failure.message}');
        emit(InvoiceDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (success) {
        debugPrint('✅ BLOC: Successfully set invoice to unloaded');
        emit(InvoiceUnloadedSuccess(invoiceDataId: event.invoiceDataId));
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
