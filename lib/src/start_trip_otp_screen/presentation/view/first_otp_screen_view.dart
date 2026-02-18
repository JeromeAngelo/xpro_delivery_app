import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/digital_clock.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/odometer_input.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/otp_instructions.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/otp_input.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/confirm_button.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/trip_details_dialog.dart';

import '../../../../core/common/app/features/otp/intransit_otp/presentation/bloc/otp_bloc.dart';
import '../../../../core/common/app/features/otp/intransit_otp/presentation/bloc/otp_event.dart';
import '../../../../core/common/app/features/otp/intransit_otp/presentation/bloc/otp_state.dart';

class FirstOtpScreenView extends StatefulWidget {
  const FirstOtpScreenView({super.key});

  @override
  State<FirstOtpScreenView> createState() => _FirstOtpScreenViewState();
}

class _FirstOtpScreenViewState extends State<FirstOtpScreenView> {
  late final AuthBloc _authBloc;
  late final OtpBloc _otpBloc;

  bool _isInitialized = false;

  String enteredOtp = '';
  String enteredOdometer = '';

  String? generatedOtp;
  String? otpId;
  String? tripId;

  AuthState? _cachedAuthState;
  OtpState? _cachedOtpState;

  StreamSubscription? _authSubscription;
  StreamSubscription? _otpSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupSubscriptions();
    _loadInitialData();
    RouteUtils.saveCurrentRoute('/first-otp');
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _otpBloc = context.read<OtpBloc>();
  }

  void _setupSubscriptions() {
    _authSubscription = _authBloc.stream.listen((state) {
      if (!mounted) return;

      // Cache auth state (optional)
      _cachedAuthState = state;

      if (state is UserTripLoaded && state.trip.id != null) {
        final tId = state.trip.id!.toString().trim();
        if (tId.isEmpty) return;

        debugPrint('🎫 Trip loaded -> Load OTP by tripId=$tId');

        setState(() {
          tripId = tId;
        });

        // ✅ Only use trip-based OTP loader
        _otpBloc.add(LoadOtpByTripIdEvent(tId));
      }
    });

    _otpSubscription = _otpBloc.stream.listen((state) {
      if (!mounted) return;

      // Cache otp state (optional)
      _cachedOtpState = state;

      // ✅ Only listen for trip-based loaded state
      if (state is OtpDataLoaded) {
        debugPrint('🔑 OTP loaded by trip');
        debugPrint('   🆔 otpId=${state.otp.id}');
        debugPrint('   🔐 generatedCode=${state.otp.generatedCode}');

        setState(() {
          otpId = state.otp.id;
          generatedOtp = state.otp.generatedCode;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (!mounted) return;

    if (storedData == null || storedData.trim().isEmpty) {
      debugPrint('⚠️ No user_data in prefs');
      _isInitialized = true;
      return;
    }

    final userData = jsonDecode(storedData);
    final userId = userData['id'];
    final tripData = userData['trip'] as Map<String, dynamic>?;

    if (userId == null) {
      debugPrint('⚠️ No userId found in prefs');
      _isInitialized = true;
      return;
    }

    debugPrint('👤 Loading local user data: $userId');
    _authBloc.add(LoadLocalUserByIdEvent(userId));

    // Load trip from local storage (offline-first)
    if (tripData != null && tripData['id'] != null) {
      final tId = tripData['id'].toString().trim();
      if (tId.isNotEmpty) {
        debugPrint('🚚 Loading local user trip for user=$userId');
        _authBloc.add(LoadLocalUserTripEvent(userId));

        // Also set tripId so UI knows
        setState(() {
          tripId = tId;
        });

        // ✅ Only trip-based OTP load
        debugPrint('🔑 Loading OTP by tripId from prefs: $tId');
        _otpBloc.add(LoadOtpByTripIdEvent(tId));
      }
    }

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _otpBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<OtpBloc, OtpState>(
            listener: (context, state) {
              if (state is OtpVerified && state.isVerified) {
                CoreUtils.showSnackBar(
                  context,
                  '${state.otpType} OTP verified successfully',
                );
                if (tripId != null) {
                  context.push('/delivery-and-timeline');
                }
              } else if (state is OtpError) {
                CoreUtils.showSnackBar(context, state.message);
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('OTP Verification'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          "Start Trip Verification",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const OTPInstructions(),

                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const TripDetailsDialog(),
                              );
                            },
                            icon: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(
                              'View Trip Details',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        const DigitalClocks(),
                        OTPInput(
                          onOtpChanged: (otp) {
                            if (mounted) setState(() => enteredOtp = otp);
                          },
                        ),
                        const SizedBox(height: 20),
                        OdometerInput(
                          onOdometerChanged: (odometer) {
                            if (mounted) {
                              setState(() => enteredOdometer = odometer);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Confirm button uses ONLY OtpDataLoaded (trip-based)
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    debugPrint('🔄 Auth State: $state');
                    final effectiveState =
                        (state is UserTripLoaded) ? state : _cachedAuthState;

                    if (effectiveState is UserTripLoaded &&
                        effectiveState.trip.id != null &&
                        generatedOtp != null) {
                      debugPrint(
                        '🎯 Rendering button with Trip ID: ${effectiveState.trip.id}',
                      );

                      return ConfirmButtonOtp(
                        enteredOtp: enteredOtp,
                        generatedOtp: generatedOtp!,
                        tripId: effectiveState.trip.id!,
                        otpId: otpId ?? '',
                        odometerReading: enteredOdometer,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _loadingFooter(BuildContext context, String text) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Center(
  //       child: Column(
  //         children: [
  //           const CircularProgressIndicator(),
  //           const SizedBox(height: 16),
  //           Text(
  //             text,
  //             style: TextStyle(color: Theme.of(context).colorScheme.secondary),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _otpSubscription?.cancel();
    super.dispose();
  }
}
