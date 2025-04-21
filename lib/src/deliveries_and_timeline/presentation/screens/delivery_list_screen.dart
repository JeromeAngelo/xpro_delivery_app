import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/delivery_list_tile.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/end_trip_btn.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> 
    with AutomaticKeepAliveClientMixin {
  CustomerState? _cachedState;
  DeliveryUpdateState? _cachedDeliveryState;
  late final AuthBloc _authBloc;
  late final CustomerBloc _customerBloc;
  late final DeliveryUpdateBloc _deliveryUpdateBloc;
  bool _isInitialized = false;
  StreamSubscription? _authSubscription;
  StreamSubscription? _customerSubscription;
  StreamSubscription? _deliverySubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
    _checkDeliveryStatus();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _customerBloc = context.read<CustomerBloc>();
    _deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
  }

  void _checkDeliveryStatus() {
    SharedPreferences.getInstance().then((prefs) {
      final storedData = prefs.getString('user_data');
      if (storedData != null) {
        final userData = jsonDecode(storedData);
        final tripData = userData['trip'] as Map<String, dynamic>?;
        if (tripData != null && tripData['id'] != null) {
          _deliveryUpdateBloc
            ..add(CheckLocalEndDeliveryStatusEvent(tripData['id']))
            ..add(CheckEndDeliveryStatusEvent(tripData['id']));
        }
      }
    });
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      final customerState = _customerBloc.state;
      if (customerState is CustomerLoaded) {
        _cachedState = customerState;
      }

      SharedPreferences.getInstance().then((prefs) {
        if (!mounted) return;

        final storedData = prefs.getString('user_data');
        if (storedData != null) {
          final userData = jsonDecode(storedData);
          final userId = userData['id'];
          final tripData = userData['trip'] as Map<String, dynamic>?;

          if (userId != null) {
            _authBloc.add(LoadLocalUserByIdEvent(userId));

            if (tripData != null && tripData['id'] != null) {
              _authBloc.add(LoadLocalUserTripEvent(tripData['id']));
              _customerBloc.add(LoadLocalCustomersEvent(tripData['id']));
            }
          }
        }
      });

      _authSubscription = _authBloc.stream.listen((state) {
        if (!mounted) return;
        if (state is UserTripLoaded && state.trip.id != null) {
          _customerBloc.add(LoadLocalCustomersEvent(state.trip.id!));
        }
      });

      _customerSubscription = _customerBloc.stream.listen((state) {
        if (!mounted) return;
        if (state is CustomerLoaded) {
          setState(() => _cachedState = state);
        }
      });

      _deliverySubscription = _deliveryUpdateBloc.stream.listen((state) {
        if (!mounted) return;
        if (state is EndDeliveryStatusChecked) {
          setState(() => _cachedDeliveryState = state);
          debugPrint('📊 Delivery status updated: ${state.stats}');
        }
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is UserTripLoaded && state.trip.id != null) {
              _customerBloc.add(LoadLocalCustomersEvent(state.trip.id!));
            }
          },
        ),
        BlocListener<CustomerBloc, CustomerState>(
          listener: (context, state) {
            if (state is CustomerLoaded) {
              setState(() => _cachedState = state);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is UserTripLoaded && state.trip.id != null) {
              _deliveryUpdateBloc
                ..add(CheckLocalEndDeliveryStatusEvent(state.trip.id!))
                ..add(CheckEndDeliveryStatusEvent(state.trip.id!));
            }
          },
        ),
      ],
      child: Scaffold(
        body: _cachedState is CustomerLoaded
            ? _buildCustomerList((_cachedState as CustomerLoaded).customer)
            : _buildLoadingState(),
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerEntity> customers) {
    debugPrint('📋 Building customer list with ${customers.length} customers');
    
    // Determine if the End Trip button should be visible
    bool showEndTripButton = false;
    
    if (_cachedDeliveryState is EndDeliveryStatusChecked) {
      final stats = (_cachedDeliveryState as EndDeliveryStatusChecked).stats;
      final total = stats['total'] as int? ?? 0;
      final completed = stats['completed'] as int? ?? 0;
      final pending = stats['pending'] as int? ?? 0;
      
      debugPrint('📊 Delivery Status: Total=$total, Completed=$completed, Pending=$pending');
      
      // Show End Trip button only if all customers have been processed
      // (either completed or marked as undeliverable)
      showEndTripButton = total > 0 && pending == 0;
      
      debugPrint('🔘 End Trip Button visible: $showEndTripButton');
    }
    
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_authBloc.state is UserTripLoaded) {
                final tripId = (_authBloc.state as UserTripLoaded).trip.id!;
                _customerBloc.add(GetCustomerEvent(tripId));
                _deliveryUpdateBloc.add(CheckEndDeliveryStatusEvent(tripId));
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final customer = customers[index];
                        debugPrint('🏪 Rendering customer: ${customer.storeName}');
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: DeliveryListTile(
                            customer: customer,
                            isFromLocal: true,
                            onTap: () {
                              _customerBloc.add(GetCustomerLocationEvent(customer.id!));
                              context.go('/delivery-and-invoice/${customer.id}', extra: customer);
                            },
                          ),
                        );
                      },
                      childCount: customers.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Only show the End Trip button if all customers have been processed
        if (showEndTripButton) const EndTripButton(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading customer data...'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _customerSubscription?.cancel();
    _deliverySubscription?.cancel();
   
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
