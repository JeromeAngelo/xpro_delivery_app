import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_by_customerId.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/usecase/get_return_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_state.dart';
class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final GetReturnUsecase _getReturns;
  final GetReturnByCustomerId _getReturnByCustomerId;
  ReturnState? _cachedState;

  ReturnBloc({
    required GetReturnUsecase getReturns,
    required GetReturnByCustomerId getReturnByCustomerId,
  })  : _getReturns = getReturns,
        _getReturnByCustomerId = getReturnByCustomerId,
        super(const ReturnInitial()) {
    on<GetReturnsEvent>(_onGetReturnsHandler);
    on<LoadLocalReturnsEvent>(_onLoadLocalReturns);
    on<GetReturnByCustomerIdEvent>(_onGetReturnByCustomerIdHandler);
  }

  Future<void> _onGetReturnsHandler(
    GetReturnsEvent event,
    Emitter<ReturnState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
    } else {
      emit(const ReturnLoading());
    }

    final result = await _getReturns(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load returns: ${failure.message}');
        emit(ReturnError(failure.message));
      },
      (returns) {
        debugPrint('✅ Loaded ${returns.length} returns for trip: ${event.tripId}');
        final newState = ReturnLoaded(returns);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onLoadLocalReturns(
  LoadLocalReturnsEvent event,
  Emitter<ReturnState> emit,
) async {
  emit(const ReturnLoading());
  
  final result = await _getReturns.loadFromLocal(event.tripId);
  result.fold(
    (failure) {
      emit(ReturnError(failure.message));
      add(GetReturnsEvent(event.tripId));
    },
    (returns) {
      emit(ReturnLoaded(returns));
      add(GetReturnsEvent(event.tripId));
    },
  );
}


  Future<void> _onGetReturnByCustomerIdHandler(
    GetReturnByCustomerIdEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(const ReturnLoading());
    final result = await _getReturnByCustomerId(event.customerId);
    result.fold(
      (failure) => emit(ReturnError(failure.message)),
      (returnItem) => emit(ReturnByCustomerLoaded(returnItem)),
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
