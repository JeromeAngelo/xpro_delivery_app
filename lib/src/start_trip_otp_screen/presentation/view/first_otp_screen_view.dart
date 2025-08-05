import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/presentation/bloc/otp_state.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/digital_clock.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/odometer_input.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/otp_instructions.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/otp_input.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/confirm_button.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/trip_details_dialog.dart';

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

      if (state is UserTripLoaded && state.trip.id != null) {
        setState(() => _cachedAuthState = state);
        debugPrint('🎫 Loading OTP for trip: ${state.trip.id}');

        // Set the trip ID from the auth state
        setState(() {
          tripId = state.trip.id;
        });

        // Load OTP for this trip
        _otpBloc.add(LoadOtpByTripIdEvent(state.trip.id!));
      }
    });

    _otpSubscription = _otpBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is OtpDataLoaded) {
        debugPrint('🔑 OTP data loaded - ID: ${state.otp.id}');
        setState(() {
          otpId = state.otp.id;
        });
        if (otpId != null) {
          _otpBloc.add(LoadOtpByIdEvent(otpId!));
        }
      } else if (state is OtpByIdLoaded) {
        debugPrint(
          '🔑 OTP loaded - Generated code: ${state.otp.generatedCode}',
        );
        setState(() {
          generatedOtp = state.otp.generatedCode;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (mounted && storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (userId != null) {
        debugPrint('👤 Loading user data for ID: $userId');

        // First load local user data
        _authBloc.add(LoadLocalUserByIdEvent(userId));

        // Then load the user's trip from local storage
        if (tripData != null && tripData['id'] != null) {
          debugPrint('🚚 Loading trip data for ID: ${tripData['id']}');
          _authBloc.add(LoadLocalUserTripEvent(userId));

          // Also set the trip ID directly from stored data
          setState(() {
            tripId = tripData['id'];
          });

          // Load OTP for this trip
          _otpBloc.add(LoadOtpByTripIdEvent(tripData['id']));
        }
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

                        // Trip Details Button
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
                BlocBuilder<OtpBloc, OtpState>(
                  builder: (context, state) {
                    debugPrint('🔄 OTP State: $state');
                    debugPrint('📍 Current Trip ID: $tripId');
                    debugPrint('🔑 Current OTP ID: $otpId');

                    final effectiveState =
                        (state is OtpByIdLoaded) ? state : _cachedOtpState;

                    if (effectiveState is OtpByIdLoaded &&
                        tripId != null &&
                        otpId != null) {
                      return ConfirmButtonOtp(
                        enteredOtp: enteredOtp,
                        generatedOtp: effectiveState.otp.generatedCode ?? '',
                        odometerReading: enteredOdometer,
                        tripId: tripId!,
                        otpId: otpId!,
                      );
                    }

                    // Show trip loading indicator
                    return BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is UserTripLoading) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Loading trip data...",
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is UserTripLoaded) {
                          // Trip is loaded, but OTP might still be loading
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Loading OTP data...",
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is AuthError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Error loading trip: ${state.message}",
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Retry loading user trip
                                      _loadInitialData();
                                    },
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  "Loading trip data...",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _otpSubscription?.cancel();
    super.dispose();
  }
}
