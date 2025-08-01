import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
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
    
    if (storedData != null && mounted) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];
      
      if (userId != null) {
        debugPrint('📱 Loading user data for ID: $userId (offline-first)');
        
        // 📱 OFFLINE-FIRST: Load local data immediately
        _authBloc.add(LoadLocalUserByIdEvent(userId));
        _authBloc.add(LoadLocalUserTripEvent(userId));
        
        // 🌐 Then sync remote data if online
        final connectivity = context.read<ConnectivityProvider>();
        if (connectivity.isOnline) {
          debugPrint('🌐 Online: Syncing fresh user data');
          _authBloc.add(LoadUserByIdEvent(userId));
          _authBloc.add(GetUserTripEvent(userId));
        } else {
          debugPrint('📱 Offline: Using cached user data only');
        }
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            debugPrint('🎯 AuthBloc state changed in header: $state');
            
            if (state is UserByIdLoaded) {
              setState(() => _cachedState = state);
              debugPrint('✅ Cached auth state updated in header');
            }
          },
        ),
      ],
      child: SliverAppBar(
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
                
                // 📶 Network status indicator (small)
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, child) {
                    if (!connectivity.isOnline) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    // Use cached state if available for better UX
                    final effectiveState = (state is UserByIdLoaded) 
                        ? state 
                        : _cachedState;
                    
                    if (effectiveState is UserByIdLoaded) {
                      return Column(
                        children: [
                          Text(
                            effectiveState.user.name ?? 'No Driver Assigned',
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Trip #${effectiveState.user.tripNumberId ?? 'Not Assigned'}',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      );
                    }
                    
                    // Show loading only if no cached data
                    return Column(
                      children: [
                        Text(
                          _cachedState != null ? 'Updating...' : 'Loading user data...',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (state is AuthLoading && _cachedState == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
