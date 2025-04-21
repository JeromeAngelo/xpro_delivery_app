import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/usecase/get_completed_customer_by_id_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';

class CompletedCustomerBloc
    extends Bloc<CompletedCustomerEvent, CompletedCustomerState> {
  final GetCompletedCustomer _getCompletedCustomers;
  final GetCompletedCustomerById _getCompletedCustomerById;
  CompletedCustomerState? _cachedState;
   final InvoiceBloc _invoiceBloc;

  CompletedCustomerBloc({
    required InvoiceBloc invoiceBloc,
    required GetCompletedCustomer getCompletedCustomers,
    required GetCompletedCustomerById getCompletedCustomerById,
  })  : _getCompletedCustomers = getCompletedCustomers,
        _getCompletedCustomerById = getCompletedCustomerById,
        _invoiceBloc = invoiceBloc,
        super(const CompletedCustomerInitial()) {
    on<GetCompletedCustomerEvent>(_getCompletedCustomerHandler);
    on<GetCompletedCustomerByIdEvent>(_getCompletedCustomerByIdHandler);
    on<LoadLocalCompletedCustomerEvent>(_onLoadLocalCompletedCustomers);
    on<LoadLocalCompletedCustomerByIdEvent>(_onLoadLocalCompletedCustomerById);
  }
Future<void> _getCompletedCustomerHandler(
  GetCompletedCustomerEvent event,
  Emitter<CompletedCustomerState> emit,
) async {
  if (_cachedState != null) {
    emit(_cachedState!);
  } else {
    emit(const CompletedCustomerLoading());
  }

  final result = await _getCompletedCustomers(event.tripId);
  result.fold(
    (failure) => emit(CompletedCustomerError(failure.message)),
    (customers) {
      _invoiceBloc.add(const GetInvoiceEvent());

      final newState = CompletedCustomerLoaded(
        customers: customers,
        invoice: _invoiceBloc.state,
      );
      _cachedState = newState;
      emit(newState);
    },
  );
}

  Future<void> _getCompletedCustomerByIdHandler(
    GetCompletedCustomerByIdEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    emit(const CompletedCustomerLoading());
    final result = await _getCompletedCustomerById(event.customerId);
    result.fold(
      (failure) => emit(CompletedCustomerError(failure.message)),
      (customer) => emit(CompletedCustomerByIdLoaded(customer)),
    );
  }
Future<void> _onLoadLocalCompletedCustomers(
  LoadLocalCompletedCustomerEvent event,
  Emitter<CompletedCustomerState> emit,
) async {
  debugPrint('📱 Loading local completed customers for trip: ${event.tripId}');
  emit(const CompletedCustomerLoading());

  final result = await _getCompletedCustomers.loadFromLocal(event.tripId);
  
  result.fold(
    (failure) {
      debugPrint('⚠️ Local load failed, fetching from remote');
      add(GetCompletedCustomerEvent(event.tripId));
    },
    (customers) {
      if (customers.isEmpty) {
        debugPrint('📭 No local data found, syncing from remote');
        add(GetCompletedCustomerEvent(event.tripId));
      } else {
        debugPrint('✅ Loaded ${customers.length} completed customers from local storage');
        _invoiceBloc.add(const GetInvoiceEvent());
        
        final newState = CompletedCustomerLoaded(
          customers: customers,
          invoice: _invoiceBloc.state,
          isFromLocal: true,
        );
        _cachedState = newState;
        emit(newState);
        
        // Background sync
        add(GetCompletedCustomerEvent(event.tripId));
      }
    },
  );
}

  Future<void> _onLoadLocalCompletedCustomerById(
    LoadLocalCompletedCustomerByIdEvent event,
    Emitter<CompletedCustomerState> emit,
  ) async {
    debugPrint(
        '📱 Loading local completed customer by ID: ${event.customerId}');
    emit(const CompletedCustomerLoading());

    final result =
        await _getCompletedCustomerById.loadFromLocal(event.customerId);
    result.fold(
      (failure) {
        debugPrint('⚠️ Local fetch failed: ${failure.message}');
        emit(CompletedCustomerError(failure.message));
      },
      (customer) {
        debugPrint('✅ Found completed customer: ${customer.storeName}');
        debugPrint('   📦 Updates: ${customer.deliveryStatus.length}');
        debugPrint('   🧾 Invoices: ${customer.invoices.length}');
        emit(CompletedCustomerByIdLoaded(customer));
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
