import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/sync_service.dart';
import 'package:x_pro_delivery_app/core/utils/route_utils.dart';
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final _syncService = sl<SyncService>();
  double _progress = 0.0;
  String _statusText = "Checking Tripticket......";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startSync();
    _listenToProgress();
  }

  void _startSync() async {
    final hasTrip = await _syncService.checkUserHasTrip(context);
    
    if (!hasTrip) {
      setState(() => _statusText = "No active trip found");
      debugPrint('📱 No active trip - navigating to home');
      if (mounted) context.go('/homepage');
      return;
    }

      // Check if there was an active route before app was closed
  final lastActiveRoute = await RouteUtils.getLastActiveRoute();
  
  setState(() => _statusText = "Syncing data...");
  debugPrint('🔄 Active trip found - starting sync');
  
  // Start sync and set up a completion callback
  _syncService.syncAllData(context).then((_) {
    if (mounted) {
      if (lastActiveRoute != null) {
        debugPrint('🧭 Navigating to last active route: $lastActiveRoute');
        context.go(lastActiveRoute);
      } else {
        debugPrint('🏠 No saved route - navigating to homepage');
        context.go('/homepage');
      }
    }
  });

    setState(() => _statusText = "Syncing data...");
    debugPrint('🔄 Active trip found - starting sync');
    _syncService.syncAllData(context);
  }

  void _listenToProgress() {
    debugPrint('🎯 Setting up progress listener');
    _syncService.progressStream.listen(
      (progress) {
        debugPrint('📊 Progress update: ${(progress * 100).toInt()}%');
        if (mounted) {
          setState(() {
            _progress = progress;
            if (progress >= 1.0) {
              debugPrint('✅ Sync complete - navigating');
              context.go('/homepage');
            }
          });
        }
      },
      onError: (error) => debugPrint('❌ Progress stream error: $error'),
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'X Pro Delivery',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusText,
                        style: Theme.of(context).textTheme.bodyLarge,
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
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                _startSync();
                context.go('/homepage');
              },
              child: Text(
                'Continue in Background',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
