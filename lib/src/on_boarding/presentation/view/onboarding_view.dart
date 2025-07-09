import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    context.read<OnboardingBloc>().add(const CheckIfUserIsFirstTimerEvent());
  }

  Future<void> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'This app requires location services to be enabled for delivery tracking.',
            ),
            actions: [
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  if (!mounted) return;
                  Navigator.pop(context);
                  _checkAndRequestPermissions();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is required for delivery tracking. Please enable it in settings.',
            ),
            actions: [
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  if (!mounted) return;
                  Navigator.pop(context);
                  _checkAndRequestPermissions();
                },
              ),
            ],
          );
        },
      );
    }
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
                          context
                              .read<OnboardingBloc>()
                              .add(const CacheFirstTimerEvent());
                        },
                        child: const Text('Get Started'),
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