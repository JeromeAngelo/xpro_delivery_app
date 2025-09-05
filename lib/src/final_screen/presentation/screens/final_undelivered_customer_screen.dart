import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/undelivered_customer/widget/undelivered_customer_dashboard.dart';

import '../widget/final_undelivered_customer_list.dart';

class FinalUndeliveredCustomerScreen extends StatefulWidget {
  const FinalUndeliveredCustomerScreen({super.key});

  @override
  State<FinalUndeliveredCustomerScreen> createState() => _FinalUndeliveredCustomerScreenState();
}

class _FinalUndeliveredCustomerScreenState extends State<FinalUndeliveredCustomerScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final CancelledInvoiceBloc _cancelledInvoiceBloc;
  bool _isDataInitialized = false;
  bool _isLoading = true;
  String? _currentTripId;
  List<CancelledInvoiceEntity> _currentCancelledInvoices = [];
  bool _isOffline = false;
  CancelledInvoiceState? _cachedState;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    
    // Force immediate data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalData();
    });
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _cancelledInvoiceBloc = context.read<CancelledInvoiceBloc>();
  }

  void _initializeLocalData() {
    if (!_isDataInitialized) {
      debugPrint('📱 SUMMARY: Initializing cancelled invoice data...');
      _loadDataImmediately();
      _isDataInitialized = true;
    }
  }

  // Immediately load data from any available source - matching collection_screen pattern
  Future<void> _loadDataImmediately() async {
    debugPrint('🚀 SUMMARY: Attempting immediate data load');
    
    // First check if we already have data in the bloc
    final currentState = _cancelledInvoiceBloc.state;
    if (currentState is CancelledInvoicesLoaded && currentState.cancelledInvoices.isNotEmpty) {
      debugPrint('✅ SUMMARY: Using existing data from bloc state');
      _cachedState = currentState;
      setState(() {
        _currentCancelledInvoices = currentState.cancelledInvoices;
        _isOffline = false;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }
    
    // Check for offline data
    if (currentState is CancelledInvoicesOffline && currentState.cancelledInvoices.isNotEmpty) {
      debugPrint('📱 SUMMARY: Using offline data from bloc state');
      _cachedState = currentState;
      setState(() {
        _currentCancelledInvoices = currentState.cancelledInvoices;
        _isOffline = true;
        _isLoading = false;
        _isDataInitialized = true;
      });
      return;
    }
    
    // Get trip ID from auth bloc first
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      debugPrint('🔍 SUMMARY: Found trip ID in auth bloc: $_currentTripId');
      
      if (!_isDataInitialized) {
        _isDataInitialized = true;
        // Load local data first for immediate display
        _cancelledInvoiceBloc.add(LoadLocalCancelledInvoicesByTripIdEvent(_currentTripId!));
        // Then fetch remote data
        _cancelledInvoiceBloc.add(LoadCancelledInvoicesByTripIdEvent(_currentTripId!));
      }
      return;
    }
    
    // Try multiple sources for trip ID
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Check user_trip_data first
    final tripData = prefs.getString('user_trip_data');
    if (tripData != null) {
      try {
        final tripJson = jsonDecode(tripData);
        if (tripJson['id'] != null) {
          _currentTripId = tripJson['id'];
          debugPrint('🔍 SUMMARY: Found trip ID in user_trip_data: $_currentTripId');
          _loadDataWithTripId();
          return;
        }
      } catch (e) {
        debugPrint('⚠️ SUMMARY: Error parsing user_trip_data: $e');
      }
    }
    
    // 2. Check user_data for embedded trip
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        final userJson = jsonDecode(userData);
        
        // Check for trip object
        final trip = userJson['trip'] as Map<String, dynamic>?;
        if (trip != null && trip['id'] != null) {
          _currentTripId = trip['id'];
          debugPrint('🔍 SUMMARY: Found trip ID in user_data.trip: $_currentTripId');
          _loadDataWithTripId();
          return;
        }
        
        // Check for tripNumberId and resolve it
        final tripNumberId = userJson['tripNumberId'];
        if (tripNumberId != null) {
          _currentTripId = tripNumberId; // This will be resolved in the datasource
          debugPrint('🔍 SUMMARY: Found tripNumberId in user_data: $_currentTripId');
          _loadDataWithTripId();
          return;
        }
      } catch (e) {
        debugPrint('⚠️ SUMMARY: Error parsing user_data: $e');
      }
    }
    
    debugPrint('⚠️ SUMMARY: No trip ID found in any SharedPreferences data');
    setState(() => _isLoading = false);
  }

  void _loadDataWithTripId() {
    if (_currentTripId != null && !_isDataInitialized) {
      _isDataInitialized = true;
      debugPrint('📱 SUMMARY: Loading cancelled invoices for trip ID: $_currentTripId');
      
      // Load local data first for immediate display, then remote
      _cancelledInvoiceBloc.add(LoadLocalCancelledInvoicesByTripIdEvent(_currentTripId!));
      // After a short delay, load remote data to ensure fresh data
      Future.delayed(const Duration(milliseconds: 500), () {
        _cancelledInvoiceBloc.add(LoadCancelledInvoicesByTripIdEvent(_currentTripId!));
      });
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 SUMMARY: Manual refresh triggered');
    setState(() => _isLoading = true);
    
    if (_currentTripId != null) {
      debugPrint('🔄 SUMMARY: Refreshing data for trip: $_currentTripId');
      _cancelledInvoiceBloc.add(RefreshCancelledInvoicesEvent(_currentTripId!));
    } else {
      // Try to get trip ID from auth bloc
      final authState = _authBloc.state;
      if (authState is UserTripLoaded && authState.trip.id != null) {
        _currentTripId = authState.trip.id;
        debugPrint('🔍 SUMMARY: Found trip ID in auth bloc during refresh: $_currentTripId');
        _cancelledInvoiceBloc.add(RefreshCancelledInvoicesEvent(_currentTripId!));
      } else {
        // Try to get from SharedPreferences
        await _loadDataImmediately();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BlocConsumer<CancelledInvoiceBloc, CancelledInvoiceState>(
        buildWhen: (previous, current) =>
            current is CancelledInvoicesLoaded || 
            current is CancelledInvoicesOffline || 
            _cachedState == null,
        listener: (context, state) {
          if (state is CancelledInvoicesLoaded) {
            debugPrint('✅ SUMMARY: Cancelled invoices loaded: ${state.cancelledInvoices.length} items');
            _cachedState = state;
            setState(() {
              _currentCancelledInvoices = state.cancelledInvoices;
              _isOffline = false;
              _isLoading = false;
            });
          } else if (state is CancelledInvoicesOffline) {
            debugPrint('📱 SUMMARY: Cancelled invoices loaded offline: ${state.cancelledInvoices.length} items');
            _cachedState = state;
            setState(() {
              _currentCancelledInvoices = state.cancelledInvoices;
              _isOffline = true;
              _isLoading = false;
            });
          } else if (state is CancelledInvoiceError) {
            debugPrint('❌ SUMMARY: Error loading cancelled invoices: ${state.message}');
            setState(() => _isLoading = false);
          } else if (state is CancelledInvoicesEmpty) {
            debugPrint('📭 SUMMARY: No cancelled invoices found');
            setState(() {
              _currentCancelledInvoices = [];
              _isOffline = false;
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          // Show loading indicator while initial data is being fetched
          if (_isLoading && state is CancelledInvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // If we have cancelled invoices data (either loaded or offline)
          if (_currentCancelledInvoices.isNotEmpty) {
            return _buildCancelledInvoicesView();
          }

          // If we have an error
          if (state is CancelledInvoiceError) {
            return _buildErrorState(state.message);
          }

          // Default state - show empty state with refresh button
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildCancelledInvoicesView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cancelled Invoice Dashboard with passed data
            UndeliveredCustomerDashboard(
              cancelledInvoices: _currentCancelledInvoices,
              isOffline: _isOffline,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    'Undelivered List',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_isOffline) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Summary Undelivered Customer List with passed data
            FinalUndeliveredCustomerList(
              cancelledInvoices: _currentCancelledInvoices,
              isOffline: _isOffline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Undelivered Customers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Undelivered customers will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 SUMMARY: Cleaning up summary undeliverable screen resources');
    _cachedState = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
