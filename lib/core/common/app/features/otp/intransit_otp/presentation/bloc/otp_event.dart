import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadOtpByIdEvent extends OtpEvent {
  final String otpId;

  LoadOtpByIdEvent(this.otpId);

   @override
  List<Object?> get props => [otpId];
}

class LoadOtpByTripIdEvent extends OtpEvent {
  final String tripId;

  LoadOtpByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class GetGeneratedOtpEvent extends OtpEvent {}

class VerifyInTransitOtpEvent extends OtpEvent {
  final String enteredOtp;
  final String generatedOtp;
  final String tripId;
  final String otpId;
  final String odometerReading;

  VerifyInTransitOtpEvent({
    required this.enteredOtp,
    required this.generatedOtp,
    required this.tripId,
    required this.otpId,
    required this.odometerReading,
  });

  @override
  List<Object?> get props =>
      [enteredOtp, generatedOtp, tripId, otpId, odometerReading];
}

class VerifyEndDeliveryOtpEvent extends OtpEvent {
  final String enteredOtp;
  final String generatedOtp;

  VerifyEndDeliveryOtpEvent({
    required this.enteredOtp,
    required this.generatedOtp,
  });

  @override
  List<Object?> get props => [enteredOtp, generatedOtp];
}
