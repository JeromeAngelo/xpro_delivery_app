import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/create_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/delete_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/get_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/get_undeliverable_customer_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/save_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/set_undeliverable_reason.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/usecases/update_undeliverable_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_state.dart';

class UndeliverableCustomerBloc
    extends Bloc<UndeliverableCustomerEvent, UndeliverableCustomerState> {
  final GetUndeliverableCustomers _getUndeliverableCustomers;
  final GetUndeliverableCustomerById _getUndeliverableCustomerById; //I will add this function later
  final CreateUndeliverableCustomer _createUndeliverableCustomer;
  final SaveUndeliverableCustomer _saveUndeliverableCustomer;
  final UpdateUndeliverableCustomer _updateUndeliverableCustomer;
  final DeleteUndeliverableCustomer _deleteUndeliverableCustomer;
  final SetUndeliverableReason _setUndeliverableReason;

  UndeliverableCustomerState? _cachedState;

  UndeliverableCustomerBloc({
    required GetUndeliverableCustomers getUndeliverableCustomers,
    required GetUndeliverableCustomerById getUndeliverableCustomerById,
    required CreateUndeliverableCustomer createUndeliverableCustomer,
    required SaveUndeliverableCustomer saveUndeliverableCustomer,
    required UpdateUndeliverableCustomer updateUndeliverableCustomer,
    required DeleteUndeliverableCustomer deleteUndeliverableCustomer,
    required SetUndeliverableReason setUndeliverableReason,
  })  : _getUndeliverableCustomers = getUndeliverableCustomers,
        _getUndeliverableCustomerById = getUndeliverableCustomerById,
        _createUndeliverableCustomer = createUndeliverableCustomer,
        _saveUndeliverableCustomer = saveUndeliverableCustomer,
        _updateUndeliverableCustomer = updateUndeliverableCustomer,
        _deleteUndeliverableCustomer = deleteUndeliverableCustomer,
        _setUndeliverableReason = setUndeliverableReason,
        super(UndeliverableCustomerInitial()) {
    on<GetUndeliverableCustomersEvent>(_onGetUndeliverableCustomers);
    on<GetUndeliverableCustomerByIdEvent>(_onGetUndeliverableCustomerById);
    on<CreateUndeliverableCustomerEvent>(_onCreateUndeliverableCustomer);
    on<SaveUndeliverableCustomerEvent>(_onSaveUndeliverableCustomer);
    on<UpdateUndeliverableCustomerEvent>(_onUpdateUndeliverableCustomer);
    on<DeleteUndeliverableCustomerEvent>(_onDeleteUndeliverableCustomer);
    on<SetUndeliverableReasonEvent>(_onSetUndeliverableReason);
    on<LoadLocalUndeliverableCustomersEvent>(_onLoadLocalUndeliverableCustomers);
  }


 Future<void> _onLoadLocalUndeliverableCustomers(
  LoadLocalUndeliverableCustomersEvent event,
  Emitter<UndeliverableCustomerState> emit,
) async {
  debugPrint('📱 Loading local undeliverable customers');
  emit(UndeliverableCustomerLoading());
  
  final result = await _getUndeliverableCustomers.loadFromLocal(event.tripId);
  await result.fold(
    (failure) async {
      emit(UndeliverableCustomerError(failure.message));
      add(GetUndeliverableCustomersEvent(event.tripId));
    },
    (localCustomers) async {
      emit(UndeliverableCustomerLoaded(localCustomers));
      add(GetUndeliverableCustomersEvent(event.tripId));
    },
  );
}


  Future<void> _onGetUndeliverableCustomers(
    GetUndeliverableCustomersEvent event,
    Emitter<UndeliverableCustomerState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
      return;
    }

    emit(UndeliverableCustomerLoading());

    final result = await _getUndeliverableCustomers(event.tripId);
    result.fold(
      (failure) => emit(UndeliverableCustomerError(failure.message)),
      (customers) {
        final newState = UndeliverableCustomerLoaded(customers);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetUndeliverableCustomerById(
    GetUndeliverableCustomerByIdEvent event,
    Emitter<UndeliverableCustomerState> emit,
  ) async {
    emit(UndeliverableCustomerLoading());

    final result = await _getUndeliverableCustomers(event.customerId);
    result.fold(
      (failure) => emit(UndeliverableCustomerError(failure.message)),
      (customers) {
        final newState = UndeliverableCustomerLoaded(customers);
        _cachedState = newState;
        emit(newState);
      },
    );
  }
Future<void> _onCreateUndeliverableCustomer(
  CreateUndeliverableCustomerEvent event,
  Emitter<UndeliverableCustomerState> emit,
) async {
  debugPrint('🔄 Creating undeliverable customer record');
  emit(UndeliverableCustomerLoading());

  final params = CreateUndeliverableCustomerParams(
    undeliverableCustomer: event.customer,
    customerId: event.customerId,
  );

  final result = await _createUndeliverableCustomer(params);
  result.fold(
    (failure) => emit(UndeliverableCustomerError(failure.message)),
    (customer) {
      emit(UndeliverableCustomerLoaded([customer]));
      // Refresh local data immediately
      add(LoadLocalUndeliverableCustomersEvent(event.customerId));
      // Then update with remote data
      add(GetUndeliverableCustomersEvent(event.customerId));
    },
  );
}


  Future<void> _onSaveUndeliverableCustomer(
  SaveUndeliverableCustomerEvent event,
  Emitter<UndeliverableCustomerState> emit,
) async {
  final params = SaveUndeliverableCustomerParams(
    undeliverableCustomer: event.customer,
    customerId: event.customerId,
  );
  
  final result = await _saveUndeliverableCustomer(params);
  result.fold(
    (failure) => emit(UndeliverableCustomerError(failure.message)),
    (_) => add(GetUndeliverableCustomersEvent(event.customerId)),
  );
}


  Future<void> _onUpdateUndeliverableCustomer(
    UpdateUndeliverableCustomerEvent event,
    Emitter<UndeliverableCustomerState> emit,
  ) async {
    final params = UpdateUndeliverableCustomerParams(
      undeliverableCustomer: event.customer,
      tripId: event.tripId,
    );

    final result = await _updateUndeliverableCustomer(params);
    result.fold(
      (failure) => emit(UndeliverableCustomerError(failure.message)),
      (_) => add(GetUndeliverableCustomersEvent(event.tripId)),
    );
  }

  Future<void> _onDeleteUndeliverableCustomer(
    DeleteUndeliverableCustomerEvent event,
    Emitter<UndeliverableCustomerState> emit,
  ) async {
    final result = await _deleteUndeliverableCustomer(event.customerId);
    result.fold(
      (failure) => emit(UndeliverableCustomerError(failure.message)),
      (_) => emit(const UndeliverableCustomerLoaded([])),
    );
  }

  Future<void> _onSetUndeliverableReason(
    SetUndeliverableReasonEvent event,
    Emitter<UndeliverableCustomerState> emit,
  ) async {
    final params = SetUndeliverableReasonParams(
      customerId: event.customerId,
      reason: event.reason,
    );
    final result = await _setUndeliverableReason(params);
    result.fold(
      (failure) => emit(UndeliverableCustomerError(failure.message)),
      (_) => add(GetUndeliverableCustomerByIdEvent(event.customerId)),
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
