import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
class DeliveryTeamProfileHeader extends StatefulWidget {
  const DeliveryTeamProfileHeader({super.key});

  @override
  State<DeliveryTeamProfileHeader> createState() => _DeliveryTeamProfileHeaderState();
}

class _DeliveryTeamProfileHeaderState extends State<DeliveryTeamProfileHeader> {
  late final AuthBloc _authBloc;
  late final DeliveryTeamBloc _deliveryTeamBloc;
  bool _isInitialized = false;
  AuthState? _cachedState;
  DeliveryTeamState? _cachedDeliveryTeamState;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _loadInitialData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryTeamBloc = context.read<DeliveryTeamBloc>();
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');
    
    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];
      
      if (userId != null) {
        debugPrint('🔄 Loading user data for ID: $userId');
        _authBloc
          ..add(LoadLocalUserByIdEvent(userId))
          ..add(LoadUserByIdEvent(userId))
          ..add(LoadLocalUserTripEvent(userId))
          ..add(GetUserTripEvent(userId));
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Theme.of(context).colorScheme.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Image(image: AssetImage('assets/images/default_user.png')),
              ),
              const SizedBox(height: 16),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is UserByIdLoaded) {
                    return Column(
                      children: [
                        Text(
                          state.user.name ?? 'No Driver Assigned',
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Trip #${state.user.tripNumberId ?? 'Not Assigned'}',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                        ),
                      ],
                    );
                  }
                  return const Text('Loading user data...',
                      style: TextStyle(color: Colors.white));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
