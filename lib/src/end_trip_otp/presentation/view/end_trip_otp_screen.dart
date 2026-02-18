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
                CoreUtils.showSnackBar(context, 'End Trip OTP verified successfully');
                context.go('/greeting-page');
              } else if (state is EndTripOtpError) {
                CoreUtils.showSnackBar(context, state.message);
              }
            },
          ),
           BlocListener<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripDistanceCalculated) {
          debugPrint('✅ Trip distance calculated: ${state.totalDistance}');
          context.go('/final-screen');
        } else if (state is TripError) {
          CoreUtils.showSnackBar(context, state.message);
        }
      },
    ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('End Trip OTP'),
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
                          "End Trip Verification",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const EndTripOtpInstructions(),
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
                        const EndTripDigitalClock(),
                        EndTripOtpInput(
                          onOtpChanged: (otp) {
                            if (mounted) setState(() => enteredOtp = otp);
                          },
                        ),
                        const SizedBox(height: 20),
                        EndTripOdoInput(
                          onOdometerChanged: (odometer) {
                            if (mounted) setState(() => endTripOdometerReading = odometer);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    debugPrint('🔄 Auth State: $state');
                    final effectiveState = (state is UserTripLoaded) ? state : _cachedAuthState;
                    
                    if (effectiveState is UserTripLoaded && 
                        effectiveState.trip.id != null && 
                        generatedOtp != null) {
                      debugPrint('🎯 Rendering button with Trip ID: ${effectiveState.trip.id}');
                      
                      return EndTripConfirmButton(
                        enteredOtp: enteredOtp,
                        generatedOtp: generatedOtp!,
                        tripId: effectiveState.trip.id!,
                        otpId: otpId ?? '',
                        odometerReading: endTripOdometerReading ?? '',
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _endTripSubscription?.cancel();
    super.dispose();
  }
}
