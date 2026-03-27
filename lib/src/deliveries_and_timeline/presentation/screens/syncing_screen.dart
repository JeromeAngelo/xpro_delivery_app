import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/common/app/features/sync_data/cubit/sync_cubit.dart';
import '../../../../core/common/app/features/sync_data/cubit/sync_state.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  double _progress = 0.0;
  String _statusText = "Initializing...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  void _initializeSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final syncCubit = context.read<SyncCubit>();

      syncCubit.initializeAppLogging().then((_) {
        _startSync();
      });
    });
  }

  void _startSync() async {
    final syncCubit = context.read<SyncCubit>();
    await syncCubit.startSyncProcess(context);
  }

  void _handleSyncState(SyncState state) {
    switch (state.runtimeType) {
      case CheckingTrip:
        _update("Checking trip ticket...", 0.1);
        break;

      case SyncingAuthData:
        _update("Syncing user data...", 0.2);
        break;

      case AuthDataSynced:
        _update("User data synchronized", 0.3);
        break;

      case TripFound:
        final s = state as TripFound;
        _update("Trip found: ${s.tripNumber}", 0.4);
        context.read<SyncCubit>().startSyncProcess(context);
        break;

      case NoTripFound:
        _update("No active trip found", 1.0);
        context.go('/homepage');
        break;

      case SyncLoading:
        _update("Starting sync process...", 0.5);
        break;

      case SyncingTripData:
        final s = state as SyncingTripData;
        _update(s.statusMessage, 0.5 + (s.progress * 0.15));
        break;

      case ProcessingPendingOperations:
        final s = state as ProcessingPendingOperations;
        final progress = s.totalOperations > 0
            ? s.completedOperations / s.totalOperations
            : 1.0;

        _update(
          "Processing encrypted packets...",
          0.95 + (progress * 0.04),
        );
        break;

      case PendingOperationsCompleted:
        _update("Finalizing sync...", 0.99);
        break;

      case SyncCompleted:
        _update("Sync completed successfully", 1.0, done: true);
        _handleSyncCompleted();
        break;

      case SyncError:
        final s = state as SyncError;
        _update("Error: ${s.message}", 0.0, done: true);
        _showErrorDialog(s.message);
        break;
    }
  }

  void _update(String text, double progress, {bool done = false}) {
    setState(() {
      _statusText = text;
      _progress = progress;
      _isLoading = !done;
    });
  }

  void _handleSyncCompleted() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/delivery-and-timeline');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sync Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startSync();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      body: BlocListener<SyncCubit, SyncState>(
        listener: (context, state) => _handleSyncState(state),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 🔥 LOTTIE ANIMATION
                Lottie.asset(
                  'assets/images/map_anim.json',
                  width: 180,
                  repeat: true,
                ),

                const SizedBox(height: 24),

                /// TITLE
                Text(
                  "Syncing your data...",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                /// SUBTITLE
                Text(
                  "Please keep the app open and your device connected to the internet.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                /// PROGRESS LABEL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TRANSFER PROGRESS",
                      style: TextStyle(
                        color: color.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${(_progress * 100).toInt()}%",
                      style: TextStyle(
                        color: color.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// PROGRESS BAR
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: color.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color.primary),
                  ),
                ),

                const SizedBox(height: 20),

                /// STATUS TEXT
                Row(
                  children: [
                    Icon(Icons.circle,
                        size: 8, color: color.primary.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}