import 'package:equatable/equatable.dart';

abstract class EndTripOtpEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEndTripOtpByIdEvent extends EndTripOtpEvent {
  final String otpId;

  LoadEndTripOtpByIdEvent(this.otpId);

  @override
  List<Object?> get props => [otpId];
}

class LoadEndTripOtpByTripIdEvent extends EndTripOtpEvent {
  final String tripId;

  LoadEndTripOtpByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class GetEndGeneratedOtpEvent extends EndTripOtpEvent {}

class VerifyEndTripOtpEvent extends EndTripOtpEvent {
  final String enteredOtp;
  final String generatedOtp;
  final String tripId;
  final String otpId;
  final String odometerReading;
  final bool noOdometer;

  VerifyEndTripOtpEvent({
    required this.enteredOtp,
    required this.generatedOtp,
    required this.tripId,
    required this.otpId,
    required this.odometerReading,
    this.noOdometer = false,
  });

  @override
  List<Object?> get props => [
    enteredOtp,
    generatedOtp,
    tripId,
    otpId,
    odometerReading,
    noOdometer,
  ];
}

class VerifyEndTripOdoStatusEvent extends EndTripOtpEvent {
  final String id;
  final bool noOdometer;

  VerifyEndTripOdoStatusEvent({required this.id, required this.noOdometer});

  @override
  List<Object?> get props => [id, noOdometer];
}
