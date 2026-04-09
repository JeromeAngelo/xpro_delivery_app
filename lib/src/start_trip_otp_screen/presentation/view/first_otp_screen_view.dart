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
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/widgets/otp_info_card.dart';
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
  bool _skipOdometer = false;
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

        setState(() {
          tripId = state.trip.id;
        });

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
          _cachedOtpState = state;
        });
      } else if (state is OtpOdoStatusUpdated) {
        debugPrint('✅ Odometer skip confirmed for id: ${state.id}');
        setState(() {
          _skipOdometer = state.noOdometer;
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
      final tripData = userData['trip'] as Map<String, dynamic>?;

      if (userId != null) {
        debugPrint('👤 Loading user data for ID: $userId');

        _authBloc.add(LoadLocalUserByIdEvent(userId));

        if (tripData != null && tripData['id'] != null) {
          debugPrint('🚚 Loading trip data for ID: ${tripData['id']}');
          _authBloc.add(LoadLocalUserTripEvent(userId));

          setState(() {
            tripId = tripData['id'];
          });

          _otpBloc.add(LoadOtpByTripIdEvent(tripData['id']));
        }
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
          backgroundColor: colorScheme.surface,
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
                        const OTPInstructions(),
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
                        const OtpInfoCard(),
                        const SizedBox(height: 32),
                        const DigitalClocks(),
                        const SizedBox(height: 32),
                        Center(
                          child: OTPInput(
                            onOtpChanged: (otp) {
                              if (mounted) setState(() => enteredOtp = otp);
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_skipOdometer) ...[
                          OdometerInput(
                            onOdometerChanged: (odometer) {
                              if (mounted) {
                                setState(() => enteredOdometer = odometer);
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
                                  _otpBloc.add(
                                    VerifyOdoStatusEvent(
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
                  child: BlocBuilder<OtpBloc, OtpState>(
                    builder: (context, state) {
                      debugPrint('🔄 OTP State: $state');
                      debugPrint('📍 Current Trip ID: $tripId');
                      debugPrint('🔑 Current OTP ID: $otpId');

                      final effectiveState =
                          (state is OtpByIdLoaded)
                              ? state
                              : (_cachedOtpState is OtpByIdLoaded
                                  ? _cachedOtpState as OtpByIdLoaded
                                  : null);
                      final isLoading = state is OtpLoading;

                      if (effectiveState is OtpByIdLoaded &&
                          tripId != null &&
                          otpId != null) {
                        return ConfirmButtonOtp(
                          enteredOtp: enteredOtp,
                          generatedOtp: effectiveState.otp.generatedCode ?? '',
                          odometerReading: enteredOdometer,
                          tripId: tripId!,
                          otpId: otpId!,
                          noOdometer: _skipOdometer,
                          isLoading: isLoading,
                        );
                      }

                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is UserTripLoading) {
                            return _buildLoadingIndicator(
                              context,
                              'Loading trip data...',
                            );
                          }

                          if (state is UserTripLoaded) {
                            return _buildLoadingIndicator(
                              context,
                              'Loading OTP data...',
                            );
                          }

                          if (state is AuthError) {
                            return _buildErrorIndicator(context);
                          }

                          return _buildLoadingIndicator(
                            context,
                            'Loading trip data...',
                          );
                        },
                      );
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

  Widget _buildLoadingIndicator(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading trip',
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadInitialData(),
            child: const Text('Retry'),
          ),
        ],
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
