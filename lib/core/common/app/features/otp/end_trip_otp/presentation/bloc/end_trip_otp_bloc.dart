import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/usecases/end_otp_verify.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/usecases/load_end_trip_otp_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/usecases/load_end_trip_otp_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_state.dart';

import '../../domain/usecases/get_end_trip_generated.dart';
class EndTripOtpBloc extends Bloc<EndTripOtpEvent, EndTripOtpState> {
  final EndOTPVerify _verifyEndTripOtp;
  final GetEndTripGeneratedOtp _getGeneratedEndTripOtp;
  final LoadEndTripOtpById _loadEndTripOtpById;
  final LoadEndTripOtpByTripId _loadEndTripOtpByTripId;

  EndTripOtpBloc({
    required EndOTPVerify verifyEndTripOtp,
    required GetEndTripGeneratedOtp getGeneratedEndTripOtp,
    required LoadEndTripOtpById loadEndTripOtpById,
    required LoadEndTripOtpByTripId loadEndTripOtpByTripId,
  })  : _verifyEndTripOtp = verifyEndTripOtp,
        _getGeneratedEndTripOtp = getGeneratedEndTripOtp,
        _loadEndTripOtpById = loadEndTripOtpById,
        _loadEndTripOtpByTripId = loadEndTripOtpByTripId,
        super(EndTripOtpInitial()) {
    on<LoadEndTripOtpByIdEvent>(_onLoadEndTripOtpById);
    on<LoadEndTripOtpByTripIdEvent>(_onLoadEndTripOtpByTripId);
    on<VerifyEndTripOtpEvent>(_onVerifyEndTripOtp);
    on<GetEndGeneratedOtpEvent>(_onGetEndGeneratedOtp);
  }

  Future<void> _onLoadEndTripOtpById(
    LoadEndTripOtpByIdEvent event,
    Emitter<EndTripOtpState> emit,
  ) async {
    debugPrint('🔄 Loading End Trip OTP by ID: ${event.otpId}');
    emit(EndTripOtpLoading());

    final result = await _loadEndTripOtpById(event.otpId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load End Trip OTP: ${failure.message}');
        emit(EndTripOtpError(message: failure.message));
      },
      (otp) {
        debugPrint('✅ End Trip OTP loaded successfully');
        emit(EndTripOtpByIdLoaded(otp));
      },
    );
  }

  Future<void> _onLoadEndTripOtpByTripId(
    LoadEndTripOtpByTripIdEvent event,
    Emitter<EndTripOtpState> emit,
  ) async {
    debugPrint('🔄 Loading End Trip OTP for trip: ${event.tripId}');
    emit(EndTripOtpLoading());

    final result = await _loadEndTripOtpByTripId(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load End Trip OTP: ${failure.message}');
        emit(EndTripOtpError(message: failure.message));
      },
      (otp) {
        debugPrint('✅ End Trip OTP loaded successfully');
        emit(EndTripOtpDataLoaded(otp));
      },
    );
  }

  Future<void> _onGetEndGeneratedOtp(
    GetEndGeneratedOtpEvent event,
    Emitter<EndTripOtpState> emit,
  ) async {
    debugPrint('🔄 Getting generated End Trip OTP');
    emit(EndTripOtpLoading());
    
    final result = await _getGeneratedEndTripOtp();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get End Trip OTP: ${failure.message}');
        emit(EndTripOtpError(message: failure.message));
      },
      (generatedOtp) {
        debugPrint('✅ End Trip OTP generated successfully');
        emit(EndTripOtpLoaded(generatedOtp: generatedOtp));
      },
    );
  }

  Future<void> _onVerifyEndTripOtp(
    VerifyEndTripOtpEvent event,
    Emitter<EndTripOtpState> emit,
  ) async {
    debugPrint('🔄 Verifying End Trip OTP');
    emit(EndTripOtpLoading());
    
    final result = await _verifyEndTripOtp(
      EndOTPVerifyParams(
        enteredOtp: event.enteredOtp,
        generatedOtp: event.generatedOtp,
        tripId: event.tripId,
        otpId: event.otpId,
        odometerReading: event.odometerReading,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ End Trip OTP verification failed: ${failure.message}');
        emit(EndTripOtpError(message: failure.message));
      },
      (isVerified) {
        debugPrint('✅ End Trip OTP verification complete: $isVerified');
        emit(EndTripOtpVerified(
          isVerified: isVerified,
          otpType: 'endTrip',
          odometerReading: event.odometerReading,
        ));
      },
    );
  }
}
