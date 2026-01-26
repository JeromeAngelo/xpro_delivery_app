import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/collection_dashboard_screen.dart';

import '../widget/summary_completed_customer_list.dart';
class SummaryCollectionScreen extends StatefulWidget {
  const SummaryCollectionScreen({super.key});

  @override
  State<SummaryCollectionScreen> createState() =>
      _SummaryCollectionScreenState();
}

class _SummaryCollectionScreenState extends State<SummaryCollectionScreen>
    with AutomaticKeepAliveClientMixin {
  late final AuthBloc _authBloc;
  late final CollectionsBloc _collectionsBloc;

  String? _currentTripId;
  List<CollectionEntity> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _collectionsBloc = context.read<CollectionsBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollections();
    });
  }

  void _loadCollections() {
    final authState = _authBloc.state;

    if (authState is UserTripLoaded && authState.trip.id != null) {
      _currentTripId = authState.trip.id;
      debugPrint('🌐 SUMMARY: Loading collections for tripId=$_currentTripId');

      _collectionsBloc.add(
        GetCollectionsByTripIdEvent(_currentTripId!),
      );
    } else {
      debugPrint('⚠️ SUMMARY: No active trip found');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    if (_currentTripId == null) return;

    debugPrint('🔄 SUMMARY: Refreshing collections');
    _collectionsBloc.add(
      GetCollectionsByTripIdEvent(_currentTripId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BlocConsumer<CollectionsBloc, CollectionsState>(
        listener: (context, state) {
          if (state is CollectionsLoaded) {
            debugPrint(
              '✅ SUMMARY: Loaded ${state.collections.length} collections',
            );
            setState(() {
              _collections = state.collections;
              _isLoading = false;
            });
          } else if (state is CollectionsEmpty) {
            debugPrint('📭 SUMMARY: No collections found');
            setState(() {
              _collections = [];
              _isLoading = false;
            });
          } else if (state is CollectionsError) {
            debugPrint('❌ SUMMARY ERROR: ${state.message}');
            setState(() => _isLoading = false);
          }
        },
        builder: (context, state) {
          if (_isLoading && state is CollectionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_collections.isNotEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CollectionDashboardScreen(
                      collections: _collections,
                      isOffline: false, // always online now
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Completed Customers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    SummaryCompletedCustomerList(
                      collections: _collections,
                     // isOffline: false,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CollectionsError) {
            return _buildErrorState(state.message);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No completed customers yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customers will appear here once deliveries are completed',
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
  bool get wantKeepAlive => true;
}
