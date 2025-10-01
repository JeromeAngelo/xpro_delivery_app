import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
abstract class EndTripOtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EndTripOtpInitial extends EndTripOtpState {}

class EndTripOtpLoading extends EndTripOtpState {}

class EndTripOtpDataLoaded extends EndTripOtpState {
  final EndTripOtpEntity otp;
  
  EndTripOtpDataLoaded(this.otp);
  
  @override
  List<Object?> get props => [otp];
}

class EndTripOtpByIdLoaded extends EndTripOtpState {
  final EndTripOtpEntity otp;
  
  EndTripOtpByIdLoaded(this.otp);
  
  @override
  List<Object?> get props => [otp];
}

class EndTripOtpVerified extends EndTripOtpState {
  final bool isVerified;
  final String otpType;
  final String odometerReading;

  EndTripOtpVerified({
    required this.isVerified,
    required this.otpType,
    required this.odometerReading,
  });

  @override
  List<Object?> get props => [isVerified, otpType, odometerReading];
}

class EndTripOtpLoaded extends EndTripOtpState {
  final String generatedOtp;
  final String? otpId;
  final String? tripId;

  EndTripOtpLoaded({
    required this.generatedOtp,
    this.otpId,
    this.tripId,
  });

  @override
  List<Object?> get props => [generatedOtp, otpId, tripId];
}

class EndTripOtpError extends EndTripOtpState {
  final String message;

  EndTripOtpError({required this.message});

  @override
  List<Object?> get props => [message];
}
