import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_all_invoice_items.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/get_invoice_item_by_invoice_data_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/usecases/update_invoice_item_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_state.dart';


class InvoiceItemsBloc extends Bloc<InvoiceItemsEvent, InvoiceItemsState> {
  final GetInvoiceItemsByInvoiceDataId _getInvoiceItemsByInvoiceDataId;
  final GetAllInvoiceItems _getAllInvoiceItems;
  final UpdateInvoiceItemById _updateInvoiceItemById;

  InvoiceItemsState? _cachedState;

  InvoiceItemsBloc({
    required GetInvoiceItemsByInvoiceDataId getInvoiceItemsByInvoiceDataId,
    required GetAllInvoiceItems getAllInvoiceItems,
    required UpdateInvoiceItemById updateInvoiceItemById,
  })  : _getInvoiceItemsByInvoiceDataId = getInvoiceItemsByInvoiceDataId,
        _getAllInvoiceItems = getAllInvoiceItems,
        _updateInvoiceItemById = updateInvoiceItemById,
        super(const InvoiceItemsInitial()) {
    on<GetInvoiceItemsByInvoiceDataIdEvent>(_onGetInvoiceItemsByInvoiceDataId);
    on<GetAllInvoiceItemsEvent>(_onGetAllInvoiceItems);
    on<UpdateInvoiceItemByIdEvent>(_onUpdateInvoiceItemById);
    on<GetAllLocalInvoiceItemsEvent>(_onGetAllLocalInvoiceItems);
    on<GetLocalInvoiceItemsByInvoiceDataIdEvent>(_onGetLocalInvoiceItemsByInvoiceDataId);
  }

  Future<void> _onGetInvoiceItemsByInvoiceDataId(
    GetInvoiceItemsByInvoiceDataIdEvent event,
    Emitter<InvoiceItemsState> emit,
  ) async {
    emit(const InvoiceItemsLoading());
    debugPrint('🔄 BLOC: Getting invoice items for invoice data ID: ${event.invoiceDataId}');

    final result = await _getInvoiceItemsByInvoiceDataId(event.invoiceDataId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get invoice items: ${failure.message}');
        emit(InvoiceItemsError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceItems) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceItems.length} invoice items');
        final newState = InvoiceItemsByInvoiceDataIdLoaded(
          invoiceItems: invoiceItems,
          invoiceDataId: event.invoiceDataId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetAllInvoiceItems(
    GetAllInvoiceItemsEvent event,
    Emitter<InvoiceItemsState> emit,
  ) async {
    emit(const InvoiceItemsLoading());
    debugPrint('🔄 BLOC: Getting all invoice items');

    final result = await _getAllInvoiceItems();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get all invoice items: ${failure.message}');
        emit(InvoiceItemsError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceItems) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceItems.length} invoice items');
        final newState = AllInvoiceItemsLoaded(invoiceItems);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onUpdateInvoiceItemById(
    UpdateInvoiceItemByIdEvent event,
    Emitter<InvoiceItemsState> emit,
  ) async {
    emit(const InvoiceItemsLoading());
    debugPrint('🔄 BLOC: Updating invoice item: ${event.invoiceItem.id}');

    final result = await _updateInvoiceItemById(event.invoiceItem);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to update invoice item: ${failure.message}');
        emit(InvoiceItemsError(message: failure.message, statusCode: failure.statusCode));
      },
      (updatedInvoiceItem) {
        debugPrint('✅ BLOC: Successfully updated invoice item');
        final newState = InvoiceItemUpdated(updatedInvoiceItem);
        emit(newState);
        
        // If we have invoice data ID, refresh the items for that invoice
        if (updatedInvoiceItem.invoiceData.target?.id != null) {
          add(GetInvoiceItemsByInvoiceDataIdEvent(updatedInvoiceItem.invoiceData.target!.id!));
        } else {
          // Otherwise, refresh all items
          add(const GetAllInvoiceItemsEvent());
        }
      },
    );
  }

  // Local event handlers using the loadFromLocal methods from existing use cases
  Future<void> _onGetAllLocalInvoiceItems(
    GetAllLocalInvoiceItemsEvent event,
    Emitter<InvoiceItemsState> emit,
  ) async {
    emit(const InvoiceItemsLoading());
    debugPrint('🔄 BLOC: Getting all local invoice items');

    final result = await _getAllInvoiceItems.loadFromLocal();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get all local invoice items: ${failure.message}');
        emit(InvoiceItemsError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceItems) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceItems.length} local invoice items');
        final newState = AllLocalInvoiceItemsLoaded(invoiceItems);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetLocalInvoiceItemsByInvoiceDataId(
    GetLocalInvoiceItemsByInvoiceDataIdEvent event,
    Emitter<InvoiceItemsState> emit,
  ) async {
    emit(const InvoiceItemsLoading());
    debugPrint('🔄 BLOC: Getting local invoice items for invoice data ID: ${event.invoiceDataId}');

    final result = await _getInvoiceItemsByInvoiceDataId.loadFromLocal(event.invoiceDataId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get local invoice items: ${failure.message}');
        emit(InvoiceItemsError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceItems) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceItems.length} local invoice items');
        final newState = LocalInvoiceItemsByInvoiceDataIdLoaded(
          invoiceItems: invoiceItems,
          invoiceDataId: event.invoiceDataId,
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
