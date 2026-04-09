import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';

import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/presentation/bloc/end_trip_otp_state.dart';

import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_confirm_button.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_digital_clock.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_odo_input.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_otp_info_card.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_otp_input.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/widgets/end_trip_otp_instructions.dart';

import '../../../start_trip_otp_screen/presentation/widgets/trip_details_dialog.dart';

class EndTripOtpScreen extends StatefulWidget {
  const EndTripOtpScreen({super.key});

  @override
  State<EndTripOtpScreen> createState() => _EndTripOtpScreenState();
}

class _EndTripOtpScreenState extends State<EndTripOtpScreen> {
  late final AuthBloc _authBloc;
  late final EndTripOtpBloc _endTripOtpBloc;
  bool _isInitialized = false;
  bool _skipOdometer = false;
  String enteredOtp = '';
  String? generatedOtp;
  String? otpId;
  String? endTripOdometerReading;
  AuthState? _cachedAuthState;
  StreamSubscription? _authSubscription;
  StreamSubscription? _endTripSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupSubscriptions();
    _loadInitialData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _endTripOtpBloc = context.read<EndTripOtpBloc>();
  }

  void _setupSubscriptions() {
    _authSubscription = _authBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is UserTripLoaded && state.trip.id != null) {
        setState(() => _cachedAuthState = state);
        debugPrint('🎫 Loading OTP for trip: ${state.trip.id}');
        _endTripOtpBloc
          ..add(LoadEndTripOtpByTripIdEvent(state.trip.id!))
          ..add(GetEndGeneratedOtpEvent());
      }
    });

    _endTripSubscription = _endTripOtpBloc.stream.listen((state) {
      if (!mounted) return;
      if (state is EndTripOtpDataLoaded) {
        setState(() {
          otpId = state.otp.id;
          generatedOtp = state.otp.generatedCode;
        });
        debugPrint('✅ OTP Data loaded - ID: $otpId, Code: $generatedOtp');
      } else if (state is EndTripOtpOdoStatusUpdated) {
        setState(() {
          _skipOdometer = state.noOdometer;
          if (state.noOdometer) {
            endTripOdometerReading = '';
          }
        });
        CoreUtils.showSnackBar(context, 'Odometer skipped successfully');
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

      if (userId != null) {
        debugPrint('👤 Loading user data for ID: $userId');
        _authBloc.add(GetUserTripEvent(userId));
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _endTripOtpBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<EndTripOtpBloc, EndTripOtpState>(
            listener: (context, state) {
              if (state is EndTripOtpVerified && state.isVerified) {
                CoreUtils.showSnackBar(
                  context,
                  'End Trip OTP verified successfully',
                );
                context.go('/greeting-page');
              } else if (state is EndTripOtpVerified && !state.isVerified) {
                CoreUtils.showSnackBar(
                  context,
                  'End Trip OTP verification failed. Please check your OTP and try again.',
                );
              } else if (state is EndTripOtpError) {
                CoreUtils.showSnackBar(context, state.message);
              }
            },
          ),
          BlocListener<TripBloc, TripState>(
            listener: (context, state) {
              if (state is TripDistanceCalculated) {
                debugPrint(
                  '✅ Trip distance calculated: ${state.totalDistance}',
                );
                context.go('/final-screen');
              } else if (state is TripError) {
                CoreUtils.showSnackBar(context, state.message);
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'OTP Verification',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,

            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const EndTripOtpInstructions(),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const TripDetailsDialog(),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'View Trip Details',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const EndTripOtpInfoCard(),
                        const SizedBox(height: 32),
                        const EndTripDigitalClock(),
                        const SizedBox(height: 32),
                        Center(
                          child: EndTripOtpInput(
                            onOtpChanged: (otp) {
                              if (mounted) setState(() => enteredOtp = otp);
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_skipOdometer) ...[
                          EndTripOdoInput(
                            onOdometerChanged: (odometer) {
                              if (mounted) {
                                setState(
                                  () => endTripOdometerReading = odometer,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                if (otpId != null) {
                                  _endTripOtpBloc.add(
                                    VerifyEndTripOdoStatusEvent(
                                      id: otpId!,
                                      noOdometer: true,
                                    ),
                                  );
                                } else {
                                  CoreUtils.showSnackBar(
                                    context,
                                    'OTP ID not loaded yet. Please wait.',
                                  );
                                }
                              },
                              child: Text(
                                'Odometer not working? Click here to skip odometer',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Odometer skipped. You can continue with OTP verification.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: BlocBuilder<AuthBloc, AuthState>(
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

                        return EndTripConfirmButton(
                          enteredOtp: enteredOtp,
                          generatedOtp: generatedOtp!,
                          tripId: effectiveState.trip.id!,
                          otpId: otpId ?? '',
                          odometerReading: endTripOdometerReading ?? '',
                          noOdometer: _skipOdometer,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
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
    _endTripSubscription?.cancel();
    super.dispose();
  }
}
