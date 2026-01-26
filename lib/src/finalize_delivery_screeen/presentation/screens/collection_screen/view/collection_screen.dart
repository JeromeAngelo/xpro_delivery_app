import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/domain/entity/collection_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/presentation/bloc/collections_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/collection_dashboard_screen.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/completed_customer_list.dart';
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with AutomaticKeepAliveClientMixin {

  late final CollectionsBloc _collectionsBloc;
  late final AuthBloc _authBloc;

  String? _currentTripId;

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
      _collectionsBloc.add(
        GetCollectionsByTripIdEvent(_currentTripId!),
      );
    }
  }

  Future<void> _refreshData() async {
    if (_currentTripId != null) {
      _collectionsBloc.add(
        RefreshCollectionsEvent(_currentTripId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(
          onPressed: () => context.go('/finalize-deliveries'),
        ),
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is UserTripLoaded) {
              return Text(
                'Trip #${state.trip.tripNumberId}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                    ),
              );
            }
            return const Text('Loading Trip...');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocBuilder<CollectionsBloc, CollectionsState>(
          builder: (context, state) {

            if (state is CollectionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CollectionsLoaded) {
              return _buildCollectionsView(state.collections);
            }

            if (state is CollectionsEmpty) {
              return _buildEmptyState();
            }

            if (state is CollectionsError) {
              return _buildErrorState(state.message);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCollectionsView(List<CollectionEntity> collections) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CollectionDashboardScreen(
            collections: collections,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              'Completed Customers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          CompletedCustomerList(
            collections: collections,
          ),
        ],
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
            'No collections yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Collections will appear here once deliveries are completed',
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
