import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_generated_otp.dart';
import '../../domain/usecases/load_otp_by_id.dart';
import '../../domain/usecases/load_otp_by_trip_id.dart';
import '../../domain/usecases/verify_in_transit.dart';
import '../../domain/usecases/verify_odo_status.dart';
import '../../domain/usecases/veryfy_in_end_delivery.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final LoadOtpByTripId _loadOtpByTripId;
  final VerifyInTransit _verifyInTransit;
  final VerifyInEndDelivery _verifyEndDelivery;
  final GetGeneratedOtp _getGeneratedOtp;
  final LoadOtpById _loadOtpById;
  final VerifyOdoStatus _verifyOdoStatus;

  OtpBloc({
    required LoadOtpByTripId loadOtpByTripId,
    required VerifyInTransit verifyInTransit,
    required VerifyInEndDelivery verifyEndDelivery,
    required GetGeneratedOtp getGeneratedOtp,
    required LoadOtpById loadOtpById,
    required VerifyOdoStatus verifyOdoStatus,
  }) : _loadOtpByTripId = loadOtpByTripId,
       _verifyInTransit = verifyInTransit,
       _verifyEndDelivery = verifyEndDelivery,
       _getGeneratedOtp = getGeneratedOtp,
       _loadOtpById = loadOtpById,
       _verifyOdoStatus = verifyOdoStatus,
       super(OtpInitial()) {
    on<LoadOtpByIdEvent>(_onLoadOtpById);
    on<LoadOtpByTripIdEvent>(_onLoadOtpByTripId);
    on<VerifyInTransitOtpEvent>(_onVerifyInTransitOtp);
    on<VerifyEndDeliveryOtpEvent>(_onVerifyEndDeliveryOtp);
    on<VerifyOdoStatusEvent>(_onVerifyOdoStatus);
    on<GetGeneratedOtpEvent>(_onGetGeneratedOtp);
  }

  Future<void> _onLoadOtpById(
    LoadOtpByIdEvent event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint('🔄 Loading OTP by ID: ${event.otpId}');
    emit(OtpLoading());

    final result = await _loadOtpById(event.otpId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load OTP: ${failure.message}');
        emit(OtpError(message: failure.message));
      },
      (otp) {
        debugPrint('✅ OTP loaded successfully');
        emit(OtpByIdLoaded(otp));
      },
    );
  }

  Future<void> _onLoadOtpByTripId(
    LoadOtpByTripIdEvent event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    debugPrint('🔄 Loading OTP for trip: ${event.tripId}');

    final result = await _loadOtpByTripId(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load OTP: ${failure.message}');
        emit(OtpError(message: failure.message));
      },
      (otp) {
        debugPrint('✅ OTP loaded successfully');
        emit(OtpDataLoaded(otp));
      },
    );
  }

  Future<void> _onGetGeneratedOtp(
    GetGeneratedOtpEvent event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    debugPrint('🔄 Getting generated OTP...');

    final result = await _getGeneratedOtp();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to get OTP: ${failure.message}');
        emit(OtpError(message: failure.message));
      },
      (generatedOtp) {
        debugPrint('✅ Generated OTP received');
        emit(OtpLoaded(generatedOtp: generatedOtp));
      },
    );
  }

  Future<void> _onVerifyInTransitOtp(
    VerifyInTransitOtpEvent event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint('🔄 Verifying In-Transit OTP...');
    emit(OtpLoading());

    final result = await _verifyInTransit(
      VerifyInTransitParams(
        enteredOtp: event.enteredOtp,
        generatedOtp: event.generatedOtp,
        tripId: event.tripId,
        otpId: event.otpId,
        odometerReading: event.odometerReading,
        noOdometer: event.noOdometer,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ OTP verification failed: ${failure.message}');
        emit(OtpError(message: failure.message));
      },
      (isVerified) {
        debugPrint('✅ OTP verification complete: $isVerified');
        emit(
          OtpVerified(
            isVerified: isVerified,
            otpType: 'inTransit',
            odometerReading: event.odometerReading,
          ),
        );
      },
    );
  }

  Future<void> _onVerifyEndDeliveryOtp(
    VerifyEndDeliveryOtpEvent event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint('🔄 Verifying End-Delivery OTP...');
    emit(OtpLoading());

    final result = await _verifyEndDelivery(
      VerifyInEndDeliveryParams(
        enteredOtp: event.enteredOtp,
        generatedOtp: event.generatedOtp,
      ),
    );

    result.fold(
      (failure) {
        debugPrint(
          '❌ End-Delivery OTP verification failed: ${failure.message}',
        );
        emit(OtpError(message: failure.message));
      },
      (isVerified) {
        debugPrint('✅ End-Delivery OTP verification complete: $isVerified');
        emit(OtpVerified(isVerified: isVerified, otpType: 'endDelivery'));
      },
    );
  }

  Future<void> _onVerifyOdoStatus(
    VerifyOdoStatusEvent event,
    Emitter<OtpState> emit,
  ) async {
    debugPrint('🔄 Updating OTP noOdometer status for id: ${event.id}');
    emit(OtpLoading());

    final result = await _verifyOdoStatus(
      VerifyOdoStatusParams(id: event.id, noOdometer: event.noOdometer),
    );

    result.fold(
      (failure) {
        debugPrint('❌ verifyOdoStatus failed: ${failure.message}');
        emit(OtpError(message: failure.message));
      },
      (updated) {
        debugPrint('✅ noOdometer status updated: $updated');
        emit(OtpOdoStatusUpdated(id: event.id, noOdometer: event.noOdometer));
      },
    );
  }
}
