import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
class CollectionDashboardScreen extends StatefulWidget {
  const CollectionDashboardScreen({super.key});

  @override
  State<CollectionDashboardScreen> createState() => _CollectionDashboardScreenState();
}

class _CollectionDashboardScreenState extends State<CollectionDashboardScreen> {
  CompletedCustomerState? _cachedState;
  late final AuthBloc _authBloc;
  late final CompletedCustomerBloc _completedCustomerBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📊 Collection Dashboard initialized');
    _initializeBlocs();
    _loadInitialData();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _completedCustomerBloc = context.read<CompletedCustomerBloc>();
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');
    
    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;
      
      if (tripData != null && tripData['id'] != null) {
        debugPrint('🔄 Loading collection data for trip: ${tripData['id']}');
        _completedCustomerBloc
          ..add(LoadLocalCompletedCustomerEvent(tripData['id']))
          ..add(GetCompletedCustomerEvent(tripData['id']));
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
            if (state is UserTripLoaded && state.trip.id != null) {
              debugPrint('🎫 User trip loaded: ${state.trip.id}');
              _completedCustomerBloc
                ..add(LoadLocalCompletedCustomerEvent(state.trip.id!))
                ..add(GetCompletedCustomerEvent(state.trip.id!));
            }
          },
        ),
        BlocListener<CompletedCustomerBloc, CompletedCustomerState>(
          listener: (context, state) {
            if (state is CompletedCustomerLoaded) {
              debugPrint('✅ Collection data loaded and cached');
              setState(() => _cachedState = state);
            }
          },
        ),
      ],
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildDashboardContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection Summary',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Today\'s Collection Overview',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDashboardContent() {
    return BlocBuilder<CompletedCustomerBloc, CompletedCustomerState>(
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        if (effectiveState is CompletedCustomerLoaded) {
          final customers = effectiveState.customers;
          final totalAmount = customers.fold<double>(
            0,
            (sum, customer) => sum + (customer.totalAmount ?? 0),
          );
          final totalInvoices = customers.fold<int>(
            0,
            (sum, customer) => sum + customer.invoices.length,
          );

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 22,
            children: [
              _buildInfoItem(
                context,
                Icons.attach_money,
                '₱${NumberFormat('#,##0.00').format(totalAmount)}',
                'Total Collections',
              ),
              _buildInfoItem(
                context,
                Icons.receipt,
                totalInvoices.toString(),
                'Total Invoices',
              ),
              _buildInfoItem(
                context,
                Icons.people,
                customers.length.toString(),
                'Completed',
              ),
              _buildInfoItem(
                context,
                Icons.calendar_month_outlined,
                customers.isNotEmpty && customers.first.trip.target?.timeAccepted != null
                    ? customers.first.trip.target!.timeAccepted!.toLocal().toString().split(' ')[0]
                    : 'Today',
                'Date Completed',
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cachedState = null;
    super.dispose();
  }
}
