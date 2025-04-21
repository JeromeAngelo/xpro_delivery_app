import 'package:equatable/equatable.dart';

abstract class OnBoardingEvent extends Equatable {
  const OnBoardingEvent();

  @override
  List<Object> get props => [];
}

class CacheFirstTimerEvent extends OnBoardingEvent {
  const CacheFirstTimerEvent();
}

class CheckIfUserIsFirstTimerEvent extends OnBoardingEvent {
  const CheckIfUserIsFirstTimerEvent();
}
