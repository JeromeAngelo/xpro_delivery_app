import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:x_pro_delivery_app/core/common/app/features/sync_data/cubit/sync_cubit.dart';
import 'package:x_pro_delivery_app/core/common/app/features/sync_data/cubit/sync_state.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  double _progress = 0.0;
  String _statusText = "Initializing...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeSync();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _initializeSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncCubit = context.read<SyncCubit>();
      syncCubit.initialize().then((_) {
        _startSync();
      });
    });
  }

  void _startSync() async {
    final syncCubit = context.read<SyncCubit>();
    
    // Check if user has trip
    await syncCubit.checkUserTrip(context);
  }

  void _handleSyncState(SyncState state) {
    switch (state.runtimeType) {
      case CheckingTrip:
        setState(() {
          _statusText = "Checking Tripticket......";
          _progress = 0.1;
        });
        break;

      case SyncingAuthData:
        setState(() {
          _statusText = "Syncing user data...";
          _progress = 0.2;
        });
        break;

      case AuthDataSynced:
        setState(() {
          _statusText = "User data synchronized";
          _progress = 0.3;
        });
        break;

      case TripFound:
        final tripState = state as TripFound;
        setState(() {
          _statusText = "Trip found: ${tripState.tripNumber}";
          _progress = 0.4;
        });
        // Start sync process when trip is found
        context.read<SyncCubit>().startSyncProcess(context);
        break;

      case NoTripFound:
        setState(() {
          _statusText = "No active trip found";
          _progress = 1.0;
        });
        debugPrint('📱 No active trip - navigating to home');
        if (mounted) context.go('/homepage');
        break;

      case SyncLoading:
        setState(() {
          _statusText = "Starting sync process...";
          _progress = 0.5;
        });
        break;

      case SyncingTripData:
        final tripSyncState = state as SyncingTripData;
        setState(() {
          _statusText = tripSyncState.statusMessage;
          _progress = 0.5 + (tripSyncState.progress * 0.15); // 0.5 to 0.65
        });
        break;

      case SyncingDeliveryData:
        final deliverySyncState = state as SyncingDeliveryData;
        setState(() {
          _statusText = deliverySyncState.statusMessage;
          _progress = 0.65 + (deliverySyncState.progress * 0.2); // 0.65 to 0.85
        });
        break;

      case SyncingDependentData:
        final dependentSyncState = state as SyncingDependentData;
        setState(() {
          _statusText = dependentSyncState.statusMessage;
          _progress = 0.85 + (dependentSyncState.progress * 0.1); // 0.85 to 0.95
        });
        break;

      case ProcessingPendingOperations:
        final pendingState = state as ProcessingPendingOperations;
        final pendingProgress = pendingState.totalOperations > 0 
            ? pendingState.completedOperations / pendingState.totalOperations 
            : 1.0;
        setState(() {
          _statusText = "Processing pending operations... ${pendingState.completedOperations}/${pendingState.totalOperations}";
          _progress = 0.95 + (pendingProgress * 0.04); // 0.95 to 0.99
        });
        break;

      case PendingOperationsCompleted:
        final completedState = state as PendingOperationsCompleted;
        setState(() {
          _statusText = "Processed ${completedState.processedOperations} operations";
          _progress = 0.99;
        });
        break;

      case SyncCompleted:
        setState(() {
          _statusText = "Sync completed successfully";
          _progress = 1.0;
          _isLoading = false;
        });
        _handleSyncCompleted();
        break;

      case SyncError:
        final errorState = state as SyncError;
        setState(() {
          _statusText = "Error: ${errorState.message}";
          _progress = 0.0;
          _isLoading = false;
        });
        _handleSyncError(errorState.message);
        break;

      default:
        // Handle any other states
        break;
    }
  }

  void _handleSyncCompleted() async {
    debugPrint('✅ Sync complete - checking for saved route');
    
    // Check if there was an active route before app was closed
    final lastActiveRoute = await RouteUtils.getLastActiveRoute();
    debugPrint('🔍 Last active route found: $lastActiveRoute');

    if (mounted) {
      if (lastActiveRoute != null && lastActiveRoute.isNotEmpty) {
        debugPrint('🧭 Navigating to last active route: $lastActiveRoute');
        context.go(lastActiveRoute);
      } else {
        debugPrint('🏠 No saved route - navigating to homepage');
        context.go('/homepage');
      }
    }
  }

  void _handleSyncError(String errorMessage) {
    debugPrint('❌ Sync failed: $errorMessage');
    
    // Show error dialog
    _showErrorDialog(errorMessage);
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sync Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retrySync();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/homepage');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _retrySync() {
    setState(() {
      _progress = 0.0;
      _statusText = "Retrying sync...";
      _isLoading = true;
    });
    
    final syncCubit = context.read<SyncCubit>();
    syncCubit.resetState();
    _startSync();
  }

  void _continueInBackground() {
    debugPrint('🔄 Continue in background pressed');
    
    // Start background sync if not already syncing
    final syncCubit = context.read<SyncCubit>();
    if (!syncCubit.isSyncing) {
      syncCubit.startSyncProcess(context);
    }
    
    // Navigate to homepage
    context.go('/homepage');
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<SyncCubit, SyncState>(
        listener: (context, state) {
          _handleSyncState(state);
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              _buildLogoSection(),
              
              const SizedBox(height: 48),
              
              // Status Section
              _buildStatusSection(),
              
              const SizedBox(height: 32),
              
              // Continue Button
              if (_isLoading) _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Icon(
                Icons.local_shipping_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'X Pro Delivery',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Loading Indicator
          if (_isLoading) _buildLoadingIndicator(),
          
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status Text and Progress Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _statusText,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return TextButton(
      onPressed: _continueInBackground,
      child: Text(
        'Continue in Background',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
