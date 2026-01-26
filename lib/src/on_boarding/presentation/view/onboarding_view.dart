import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_bloc.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_event.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/bloc/onboarding_state.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  static const routeName = '/';

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _debugStoredData();
    _checkAndRequestAllPermissions();
    context.read<OnboardingBloc>().add(const CheckIfUserIsFirstTimerEvent());
  }

  void _debugStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('🔍 OnBoarding: Checking stored data...');
    debugPrint('   🔑 Has auth_token: ${prefs.containsKey('auth_token')}');
    debugPrint('   👤 Has user_data: ${prefs.containsKey('user_data')}');
    debugPrint(
      '   🆕 Is first timer: ${prefs.getBool('isFirstTimer') ?? 'NOT_SET'}',
    );
    debugPrint('   📱 All keys: ${prefs.getKeys()}');

    // If we find unexpected auth data on onboarding, clear it
    if (prefs.containsKey('auth_token')) {
      debugPrint('⚠️ Found auth token on onboarding screen, clearing it');
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }
  }

  Future<void> _checkAndRequestAllPermissions() async {
    if (_permissionsChecked) return;

    print('Starting permission check...');
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        await _showLocationServiceDialog();
      }
      return;
    }

    // Step 1: Request basic permissions first
    await _requestBasicPermissions();

    // Step 1.5: Request notification permission (Android 13+ / iOS notification access)
    await _requestNotificationPermission();

    // Step 2: Request location "when in use" first
    await _requestLocationPermissions();

    _permissionsChecked = true;
    print('Permission check completed.');
  }

  Future<void> _requestNotificationPermission() async {
    try {
      // If the permission isn't available in the platform (older OS), this will simply return granted
      final status = await Permission.notification.status;
      debugPrint('Notification permission status: $status');

      if (status.isGranted) return;

      final result = await Permission.notification.request();
      debugPrint('Notification permission request result: $result');

      if (result.isPermanentlyDenied) {
        if (mounted) {
          await _showPermissionDialog(
            'Notifications Required',
            'This app uses persistent notifications to run background location tracking. Please enable notifications in app settings.',
            'Open Settings',
            _handleOpenSettings,
          );
        }
        return;
      }

      if (result.isDenied) {
        if (mounted) {
          await _showPermissionDialog(
            'Enable Notifications',
            'To track your trip while the app is in background, please allow notifications.\n\nThe system dialog will appear when you tap "Grant".',
            'Grant',
            () async {
              if (mounted) Navigator.of(context).pop();
              await Permission.notification.request();
            },
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Notification permission check/request failed: $e');
    }
  }

  Future<void> _requestBasicPermissions() async {
    // Define basic required permissions (excluding location)
    List<Permission> basicPermissions = [Permission.camera, Permission.photos];

    // Request basic permissions
    Map<Permission, PermissionStatus> statuses =
        await basicPermissions.request();

    // Handle denied basic permissions
    List<Permission> deniedPermissions = [];
    List<Permission> permanentlyDeniedPermissions = [];

    statuses.forEach((permission, status) {
      if (status.isDenied) {
        deniedPermissions.add(permission);
      } else if (status.isPermanentlyDenied) {
        permanentlyDeniedPermissions.add(permission);
      }
    });

    // Show dialog for permanently denied permissions
    if (permanentlyDeniedPermissions.isNotEmpty && mounted) {
      await _showPermissionDialog(
        'Permissions Required',
        'The following permissions are required for the app to function properly:\n\n${permanentlyDeniedPermissions.map((p) => _getPermissionName(p)).join('\n• ')}\n\nPlease enable them in app settings.',
        'Open Settings',
        _handleOpenSettings,
      );
      return;
    }

    // Show dialog for denied permissions
    if (deniedPermissions.isNotEmpty && mounted) {
      await _showPermissionDialog(
        'Permissions Needed',
        'The app needs the following permissions to work properly:\n\n• ${deniedPermissions.map((p) => _getPermissionName(p)).join('\n• ')}',
        'Grant Permissions',
        () => _handleRequestPermissions(deniedPermissions),
      );
      return;
    }
  }

  Future<void> _requestLocationPermissions() async {
    // First request "when in use" location permission
    PermissionStatus whenInUseStatus =
        await Permission.locationWhenInUse.request();
    print('Location When In Use Status: $whenInUseStatus');

    if (whenInUseStatus.isDenied) {
      if (mounted) {
        await _showPermissionDialog(
          'Location Permission Required',
          'Location access is required for delivery tracking functionality.',
          'Grant Permission',
          () async {
            if (mounted) Navigator.of(context).pop();
            await Permission.locationWhenInUse.request();
            // Don't recursively call - let user try again manually
          },
        );
      }
      return;
    }

    if (whenInUseStatus.isPermanentlyDenied) {
      if (mounted) {
        await _showPermissionDialog(
          'Location Permission Required',
          'Location permission is permanently denied. Please enable it in app settings for delivery tracking functionality.',
          'Open Settings',
          _handleOpenSettings,
        );
      }
      return;
    }

    // If "when in use" is granted, request "always" permission
    if (whenInUseStatus.isGranted) {
      PermissionStatus alwaysStatus = await Permission.locationAlways.request();
      print('Location Always Status: $alwaysStatus');

      if (alwaysStatus.isDenied && mounted) {
        await _showPermissionDialog(
          'Always Location Access',
          'For the best delivery tracking experience, please allow location access "All the time" instead of "Only while using the app".',
          'Grant Always Access',
          () async {
            if (mounted) Navigator.of(context).pop();
            await Permission.locationAlways.request();
          },
        );
      }

      if (alwaysStatus.isPermanentlyDenied && mounted) {
        await _showPermissionDialog(
          'Always Location Access',
          'Always location permission is permanently denied. Please enable "Allow all the time" in app settings for optimal delivery tracking.',
          'Open Settings',
          _handleOpenSettings,
        );
      }
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera Access';
      case Permission.photos:
        return 'Photos Access';
      case Permission.locationWhenInUse:
        return 'Location Access';
      case Permission.locationAlways:
        return 'Always Location Access';
      default:
        return 'Required Permission';
    }
  }

  void _handleOpenSettings() async {
    await openAppSettings();
    if (mounted) {
      Navigator.of(context).pop();
      // Reset flag to allow re-checking after settings change
      _permissionsChecked = false;
      _checkAndRequestAllPermissions();
    }
  }

  void _handleRequestPermissions(List<Permission> permissions) async {
    if (mounted) {
      Navigator.of(context).pop();
    }
    await permissions.request();
    // Don't recursively call permission check here
  }

  void _handleLocationSettings() async {
    await Geolocator.openLocationSettings();
    if (mounted) {
      Navigator.of(context).pop();
      // Reset flag to allow re-checking after settings change
      _permissionsChecked = false;
      _checkAndRequestAllPermissions();
    }
  }

  Future<void> _showLocationServiceDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Service Required'),
          content: const Text(
            'This app requires location services to be enabled for delivery tracking. Please enable location services.',
          ),
          actions: [
            TextButton(
              onPressed: _handleLocationSettings,
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermissionDialog(
    String title,
    String content,
    String buttonText,
    VoidCallback onPressed,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [TextButton(onPressed: onPressed, child: Text(buttonText))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<OnboardingBloc, OnBoardingState>(
        listener: (context, state) {
          if (state is OnBoardingStatus && !state.isFirstTimer) {
            context.go('/sign-in');
          } else if (state is UserCached) {
            context.go('/sign-in');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/onboarding_image.gif',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 30),
                    if (state is CheckingIfUserIsFirstTimer ||
                        state is CachingFirstTimer)
                      const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'X Pro Delivery',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (state is OnBoardingStatus && state.isFirstTimer) ...[
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          context.read<OnboardingBloc>().add(
                            const CacheFirstTimerEvent(),
                          );
                        },
                        child: const Text('Get Started'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // explicit user-triggered notification permission request
                          await _requestNotificationPermission();
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Enable Notifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (state is OnBoardingError)
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
