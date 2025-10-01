import 'package:equatable/equatable.dart';

import '../../domain/entity/otp_entity.dart';
abstract class OtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OtpInitial extends OtpState {}

class OtpLoading extends OtpState {}

class OtpDataLoaded extends OtpState {
  final OtpEntity otp;
  
  OtpDataLoaded(this.otp);
  
  @override
  List<Object?> get props => [otp];
}

class OtpByIdLoaded extends OtpState {
  final OtpEntity otp;
  
  OtpByIdLoaded(this.otp);
  
  @override
  List<Object?> get props => [otp];
}

class OtpVerified extends OtpState {
  final bool isVerified;
  final String otpType;
  final String? odometerReading;

  OtpVerified({
    required this.isVerified,
    required this.otpType,
    this.odometerReading,
  });

  @override
  List<Object?> get props => [isVerified, otpType, odometerReading];
}

class OtpLoaded extends OtpState {
  final String generatedOtp;
  final String? otpId;
  final String? tripId;

  OtpLoaded({
    required this.generatedOtp,
    this.otpId,
    this.tripId,
  });

  @override
  List<Object?> get props => [generatedOtp, otpId, tripId];
}

class OtpError extends OtpState {
  final String message;

  OtpError({required this.message});

  @override
  List<Object?> get props => [message];
}
