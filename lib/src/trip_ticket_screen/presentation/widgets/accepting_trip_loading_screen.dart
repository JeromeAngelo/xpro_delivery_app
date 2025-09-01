import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/widgets/warning_dialog.dart';

class AcceptingTripLoadingScreen extends StatefulWidget {
  final String tripId;
  
  const AcceptingTripLoadingScreen({super.key, required this.tripId});

  @override
  State<AcceptingTripLoadingScreen> createState() => _AcceptingTripLoadingScreenState();
}

class _AcceptingTripLoadingScreenState extends State<AcceptingTripLoadingScreen> {
  bool _personnelCheckStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppDebugLogger.instance.logInfo('🎬 Accepting Trip Loading Screen initialized for trip: ${widget.tripId}');
    if (!_personnelCheckStarted) {
      _initializeAndCheckPersonnel();
    }
  }

  Future<void> _initializeAndCheckPersonnel() async {
    debugPrint('🔍 LOADING_SCREEN: Starting personnel check for trip: ${widget.tripId}');
    AppDebugLogger.instance.logInfo('🔍 Initializing personnel check for trip: ${widget.tripId}');
    
    // Get current user ID and start personnel check
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');
      
      if (storedUserData != null) {
        final userData = jsonDecode(storedUserData);
        final currentUserId = userData['id'];
        final userName = userData['name'] ?? 'Unknown';
        final userEmail = userData['email'] ?? 'Unknown';
        
        debugPrint('👤 LOADING_SCREEN: Current user details:');
        debugPrint('   - ID: $currentUserId');
        debugPrint('   - Name: $userName');
        debugPrint('   - Email: $userEmail');
        debugPrint('   - Trip ID: ${widget.tripId}');
        
        AppDebugLogger.instance.logInfo('👤 Personnel check starting for user: $userName ($currentUserId) - Trip: ${widget.tripId}');
        
        // Start the personnel check
        if (!_personnelCheckStarted && mounted) {
          _personnelCheckStarted = true;
          debugPrint('🚀 LOADING_SCREEN: Dispatching CheckTripPersonnelsEvent...');
          AppDebugLogger.instance.logInfo('🚀 Dispatching personnel check event');
          context.read<TripBloc>().add(CheckTripPersonnelsEvent(
            tripId: widget.tripId,
            userId: currentUserId,
          ));
        } else {
          debugPrint('⚠️ LOADING_SCREEN: Personnel check already started or widget unmounted');
          AppDebugLogger.instance.logWarning('⚠️ Personnel check already started or widget unmounted');
        }
      } else {
        debugPrint('❌ LOADING_SCREEN: No user data found in SharedPreferences');
        AppDebugLogger.instance.logError('❌ No user data found in SharedPreferences - redirecting to homepage');
        if (mounted) context.go('/homepage');
      }
    } catch (e) {
      debugPrint('❌ LOADING_SCREEN: Error getting user data: $e');
      AppDebugLogger.instance.logError('❌ Error getting user data: $e');
      if (mounted) context.go('/homepage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripBloc, TripState>(
      listener: (context, state) {
        debugPrint('🔄 LOADING_SCREEN: BlocListener received state: ${state.runtimeType}');
        AppDebugLogger.instance.logInfo('🔄 Trip state changed: ${state.runtimeType}');
        
        // Handle personnel check results
        if (state is TripPersonnelsChecked) {
          debugPrint('✅ LOADING_SCREEN: Personnel check passed - user is authorized');
          debugPrint('   Authorized personnel IDs: ${state.personnelIds}');
          debugPrint('   Proceeding to accept trip: ${widget.tripId}');
          AppDebugLogger.instance.logInfo('✅ Personnel check passed - user authorized for trip: ${widget.tripId}');
          AppDebugLogger.instance.logInfo('👥 Authorized personnel IDs: ${state.personnelIds}');
          // User is authorized, proceed with trip acceptance
          context.read<TripBloc>().add(AcceptTripEvent(widget.tripId));
        }
        
        if (state is TripPersonnelMismatch) {
          debugPrint('⚠️ LOADING_SCREEN: Personnel mismatch detected');
          debugPrint('   Trip ID: ${state.tripId}');
          debugPrint('   User ID: ${state.userId}');
          debugPrint('   Error Message: ${state.message}');
          debugPrint('   Showing enhanced warning dialog...');
          
          // Enhanced logging for personnel authorization issues
          AppDebugLogger.instance.logWarning('⚠️ Personnel authorization mismatch detected');
          AppDebugLogger.instance.logWarning('📋 Trip ID: ${state.tripId}');
          AppDebugLogger.instance.logWarning('👤 User ID: ${state.userId}');
          AppDebugLogger.instance.logWarning('📋 Authorization failed - user not assigned to this trip');
          AppDebugLogger.instance.logError('🚨 SECURITY: Unauthorized trip access attempt');
          AppDebugLogger.instance.logError('📋 Technical error details: ${state.message}');
          
          // Show enhanced warning dialog with user-friendly messaging
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => PersonnelWarningDialog(
              tripId: state.tripId,
              message: state.message,
            ),
          );
        }
        
        // Handle trip acceptance results
        if (state is TripAccepted) {
          debugPrint('✅ LOADING_SCREEN: Trip accepted successfully');
          debugPrint('   Trip ID: ${state.tripId}');
          debugPrint('   Starting location tracking and navigating to checklist...');
          AppDebugLogger.instance.logInfo('✅ Trip accepted successfully: ${state.tripId}');
          AppDebugLogger.instance.logInfo('📍 Starting location tracking and navigating to checklist');
          
          // Start comprehensive distance tracking for the accepted trip
          context.read<TripBloc>().add(StartLocationTrackingEvent(
            tripId: state.tripId,
            updateInterval: const Duration(minutes: 5), // Time-based: every 5 minutes
            distanceFilter: 5.0, // Distance-based: every 5 meters of movement
          ));
          
          context.go('/checklist');
        }
        
        if (state is TripError) {
          debugPrint('❌ LOADING_SCREEN: Trip acceptance error: ${state.message}');
          AppDebugLogger.instance.logError('❌ Trip acceptance error: ${state.message}');
          // Show error and go back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.go('/homepage');
        }
        
        if (state is TripPersonnelsChecking) {
          AppDebugLogger.instance.logInfo('🔍 Personnel authorization check in progress...');
        }
        
        if (state is TripAccepting) {
          AppDebugLogger.instance.logInfo('🔄 Trip acceptance in progress...');
        }
        
        if (state is LocationTrackingStarted) {
          AppDebugLogger.instance.logInfo('📍 Location tracking started for trip: ${widget.tripId}');
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/trip_accepting.gif',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),
              BlocBuilder<TripBloc, TripState>(
                builder: (context, state) {
                  String message = 'Preparing to accept trip...';
                  
                  if (state is TripPersonnelsChecking) {
                    message = 'Checking authorization...';
                  } else if (state is TripAccepting) {
                    message = 'Accepting trip...';
                  } else if (state is LocationTrackingStarted) {
                    message = 'Starting location tracking...';
                  }
                  
                  return Text(
                    message,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
