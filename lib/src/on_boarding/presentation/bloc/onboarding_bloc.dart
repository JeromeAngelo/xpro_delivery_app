import 'package:bloc/bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/cache_firstimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/usecases/check_if_user_firsttimer.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_event.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnBoardingEvent, OnBoardingState> {
  OnboardingBloc({
    required CacheFirstTimer cacheFirstTimer,
    required CheckIfUserIsFirstimer checkIfUserIsFirstimer,
  })  : _cacheFirstTimer = cacheFirstTimer,
        _checkIfUserIsFirstimer = checkIfUserIsFirstimer,
        super(const OnBoardingInitial()) {
    on<CacheFirstTimerEvent>(_cacheFirstTimerHandler);
    on<CheckIfUserIsFirstTimerEvent>(_checkIfUserIsFirstTimerHandler);
  }

  final CacheFirstTimer _cacheFirstTimer;
  final CheckIfUserIsFirstimer _checkIfUserIsFirstimer;

  Future<void> _cacheFirstTimerHandler(
    CacheFirstTimerEvent event,
    Emitter<OnBoardingState> emit,
  ) async {
    emit(const CachingFirstTimer());
    final result = await _cacheFirstTimer();

    result.fold(
      (failure) => emit(OnBoardingError(failure.message)),
      (_) => emit(const UserCached()),
    );
  }

  Future<void> _checkIfUserIsFirstTimerHandler(
    CheckIfUserIsFirstTimerEvent event,
    Emitter<OnBoardingState> emit,
  ) async {
    emit(const CheckingIfUserIsFirstTimer());
    final result = await _checkIfUserIsFirstimer();

    result.fold(
      (failure) => emit(const OnBoardingStatus(isFirstTimer: true)),
      (status) => emit(OnBoardingStatus(isFirstTimer: status)),
    );
  }
}
