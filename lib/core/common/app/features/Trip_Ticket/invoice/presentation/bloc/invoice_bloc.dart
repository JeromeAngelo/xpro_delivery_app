import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice_per_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/get_invoice_per_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/set_all_invoices_completed.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/usecase/set_invoice_unloaded.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final ProductsBloc _productsBloc;
  final GetInvoice _getInvoices;
  final GetInvoicesByTrip _getInvoicesByTrip;
  final GetInvoicesByCustomer _getInvoicesByCustomer;
  final SetAllInvoicesCompleted _setAllInvoicesCompleted;
  final SetInvoiceUnloaded _setInvoiceUnloaded; // Add the new use case
  InvoiceState? _cachedState;

  InvoiceBloc({
    required ProductsBloc productsBloc,
    required GetInvoice getInvoices,
    required GetInvoicesByTrip getInvoicesByTrip,
    required GetInvoicesByCustomer getInvoicesByCustomer,
    required SetAllInvoicesCompleted setAllInvoicesCompleted,
    required SetInvoiceUnloaded setInvoiceUnloaded, // Add parameter for the new use case
  }) : _productsBloc = productsBloc,
       _getInvoices = getInvoices,
       _getInvoicesByTrip = getInvoicesByTrip,
       _getInvoicesByCustomer = getInvoicesByCustomer,
       _setAllInvoicesCompleted = setAllInvoicesCompleted,
       _setInvoiceUnloaded = setInvoiceUnloaded, // Initialize the new use case
       super(InvoiceInitial()) {
    on<GetInvoiceEvent>(_onGetInvoiceHandler);
    on<LoadLocalInvoiceEvent>(_onLoadLocalInvoiceHandler);
    on<GetInvoicesByTripEvent>(_onGetInvoicesByTripHandler);
    on<LoadLocalInvoicesByTripEvent>(_onLoadLocalInvoicesByTripHandler);
    on<GetInvoicesByCustomerEvent>(_onGetInvoicesByCustomerHandler);
    on<LoadLocalInvoicesByCustomerEvent>(_onLoadLocalInvoicesByCustomerHandler);
    on<RefreshInvoiceEvent>(_onRefreshInvoiceHandler);
    on<SetAllInvoicesCompletedEvent>(_onSetAllInvoicesCompletedHandler);
    on<SetInvoiceUnloadedEvent>(_onSetInvoiceUnloadedHandler); // Register the new event handler
  }


  // New handler for setting all invoices to completed
  Future<void> _onSetAllInvoicesCompletedHandler(
    SetAllInvoicesCompletedEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Setting all invoices to completed for trip: ${event.tripId}');
    emit(InvoiceLoading());
    
    final result = await _setAllInvoicesCompleted(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to set invoices to completed: ${failure.message}');
        emit(InvoiceError(failure.message));
      },
      (updatedInvoices) {
        debugPrint('✅ BLOC: Successfully set ${updatedInvoices.length} invoices to completed');
        emit(AllInvoicesCompletedState(updatedInvoices, event.tripId));
        
        // Refresh the invoices list for this trip to show the updated status
        add(GetInvoicesByTripEvent(event.tripId));
      },
    );
  }

  Future<void> _onGetInvoiceHandler(
    GetInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
    } else {
      emit(InvoiceLoading());
    }
    
    final localResult = await _getInvoices.loadFromLocal();
    localResult.fold(
      (failure) => null,
      (invoices) {
        final newState = InvoiceLoaded(invoices, isFromLocal: true);
        _cachedState = newState;
        emit(newState);
      },
    );
    
    _productsBloc.add(const GetProductsEvent());

    final result = await _getInvoices();
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoices) {
        final newState = InvoiceLoaded(invoices);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

 Future<void> _onLoadLocalInvoiceHandler(
  LoadLocalInvoiceEvent event,
  Emitter<InvoiceState> emit,
) async {
  debugPrint('📱 Loading local invoices');
  emit(InvoiceLoading());

  final result = await _getInvoices.loadFromLocal();

  await result.fold(
    (failure) async => emit(InvoiceError(failure.message, isLocalError: true)),
    (localInvoices) async {
      emit(InvoiceLoaded(
        localInvoices,
        isFromLocal: true,
      ));
      debugPrint('✅ Loaded ${localInvoices.length} invoices from local storage');

      // Background remote sync
      final remoteResult = await _getInvoices();
      remoteResult.fold(
        (failure) => debugPrint('🔄 Remote sync skipped: ${failure.message}'),
        (remoteInvoices) {
          if (!emit.isDone) {
            emit(InvoiceLoaded(remoteInvoices));
            debugPrint('🔄 Updated with ${remoteInvoices.length} invoices from remote');
          }
        },
      );
    },
  );
}


  Future<void> _onGetInvoicesByTripHandler(
    GetInvoicesByTripEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    
    final result = await _getInvoicesByTrip(event.tripId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoices) => emit(TripInvoicesLoaded(invoices, event.tripId)),
    );
  }

  Future<void> _onLoadLocalInvoicesByTripHandler(
    LoadLocalInvoicesByTripEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    
    final result = await _getInvoicesByTrip.loadFromLocal(event.tripId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message, isLocalError: true)),
      (invoices) => emit(TripInvoicesLoaded(invoices, event.tripId, isFromLocal: true)),
    );
  }

  Future<void> _onGetInvoicesByCustomerHandler(
    GetInvoicesByCustomerEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    
    final result = await _getInvoicesByCustomer(event.customerId);
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoices) => emit(CustomerInvoicesLoaded(invoices, event.customerId)),
    );
  }
Future<void> _onLoadLocalInvoicesByCustomerHandler(
  LoadLocalInvoicesByCustomerEvent event,
  Emitter<InvoiceState> emit,
) async {
  debugPrint('📱 Loading local customer invoices');
  emit(InvoiceLoading());

  final result = await _getInvoicesByCustomer.loadFromLocal(event.customerId);

  await result.fold(
    (failure) async => emit(InvoiceError(failure.message, isLocalError: true)),
    (localInvoices) async {
      debugPrint('📦 Local invoices loaded with products:');
      for (var invoice in localInvoices) {
        debugPrint('   🧾 Invoice ${invoice.invoiceNumber}: ${invoice.productsList.length} products');
      }
      
      emit(CustomerInvoicesLoaded(localInvoices, event.customerId, isFromLocal: true));

      // Background remote sync
      final remoteResult = await _getInvoicesByCustomer(event.customerId);
      remoteResult.fold(
        (failure) => debugPrint('🔄 Remote sync skipped: ${failure.message}'),
        (remoteInvoices) {
          if (!emit.isDone) {
            debugPrint('🔄 Remote invoices loaded with products:');
            for (var invoice in remoteInvoices) {
              debugPrint('   🧾 Invoice ${invoice.invoiceNumber}: ${invoice.productsList.length} products');
            }
            
            // Only emit if we have valid data
            if (remoteInvoices.isNotEmpty) {
              emit(CustomerInvoicesLoaded(remoteInvoices, event.customerId));
            }
          }
        },
      );
    },
  );
}



  Future<void> _onRefreshInvoiceHandler(
    RefreshInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceRefreshing());
    
    final result = await _getInvoices();
    result.fold(
      (failure) => emit(InvoiceError(failure.message)),
      (invoices) {
        final newState = InvoiceLoaded(invoices);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

   // New handler for setting an invoice to unloaded
  Future<void> _onSetInvoiceUnloadedHandler(
    SetInvoiceUnloadedEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Setting invoice ${event.invoiceId} to unloaded');
    emit(InvoiceLoading());
    
    final result = await _setInvoiceUnloaded(event.invoiceId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to set invoice to unloaded: ${failure.message}');
        emit(InvoiceError(failure.message));
      },
      (updatedInvoice) {
        debugPrint('✅ BLOC: Successfully set invoice ${updatedInvoice.invoiceNumber} to unloaded');
        emit(InvoiceUnloadedState(updatedInvoice));
        
        // If we have a cached state with a trip ID, refresh the invoices for that trip
        if (_cachedState is TripInvoicesLoaded) {
          final tripId = (_cachedState as TripInvoicesLoaded).tripId;
          add(GetInvoicesByTripEvent(tripId));
        } 
        // If we have a cached state with a customer ID, refresh the invoices for that customer
        else if (_cachedState is CustomerInvoicesLoaded) {
          final customerId = (_cachedState as CustomerInvoicesLoaded).customerId;
          add(GetInvoicesByCustomerEvent(customerId));
        }
        // Otherwise, refresh all invoices
        else {
          add(const GetInvoiceEvent());
        }
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
