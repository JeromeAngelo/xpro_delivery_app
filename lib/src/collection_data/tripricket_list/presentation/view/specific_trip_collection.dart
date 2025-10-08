
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/tripricket_list/presentation/widgets/specific_tripticket_collection_widgets/collection_completed_customer_table.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/tripricket_list/presentation/widgets/specific_tripticket_collection_widgets/collection_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SpecificTripCollection extends StatefulWidget {
  final String tripId;

  const SpecificTripCollection({super.key, required this.tripId});

  @override
  State<SpecificTripCollection> createState() => _SpecificTripCollectionState();
}

class _SpecificTripCollectionState extends State<SpecificTripCollection> {
  @override
  void initState() {
    super.initState();
    // Load trip details
    context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId));
    // Load completed customers for this trip
    context.read<CollectionsBloc>().add(GetCollectionsByTripIdEvent(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.collectionNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/collections',
      onNavigate: (route) {
        context.go(route);
      },
      onThemeToggle: () {
        // Handle theme toggle
      },
      onNotificationTap: () {
        // Handle notification tap
      },
      onProfileTap: () {
        // Handle profile tap
      },
      disableScrolling: true,
      child: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading || state is TripInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TripTicketLoaded) {
            final trip = state.trip;

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  floating: true,
                  snap: true,
                  title: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          context.go('/collections');
                        },
                      ),
                      Text('Trip Ticket: ${trip.tripNumberId ?? 'N/A'}'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId));
                        context.read<CollectionsBloc>().add(GetCollectionsByTripIdEvent(widget.tripId));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      tooltip: 'Print Collection Report',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Printing collection report...')),
                        );
                      },
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Trip Header
                      // CollectionTripHeaderWidget(
                      //   trip: trip,
                      //   onPrintReport: () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Printing collection report...')),
                      //     );
                      //   },
                      // ),

                      const SizedBox(height: 16),

                      // Collection Dashboard - using BlocBuilder for CompletedCustomerBloc
                      BlocBuilder<CollectionsBloc, CollectionsState>(
                        builder: (context, completedState) {
                          if (completedState is CollectionsLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (completedState is CollectionsError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading completed customers: ${completedState.message}',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<CollectionsBloc>().add(
                                          GetCollectionsByTripIdEvent(widget.tripId),
                                        );
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (completedState is CollectionsLoaded) {
                            return CollectionTripDashboardWidget(
                              trip: trip,
                              completedCustomers: completedState.collections,
                              isLoading: false,
                            );
                          }

                          // Default case
                          return CollectionTripDashboardWidget(
                            trip: trip,
                            completedCustomers: [],
                            isLoading: true,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Completed Customers Table
                      BlocBuilder<CollectionsBloc, CollectionsState>(
                        builder: (context, completedState) {
                          if (completedState is CollectionsLoading) {
                            return const CollectionCompletedCustomersTable(
                              tripId: '',
                              completedCustomers: [],
                              isLoading: true,
                            );
                          }

                          if (completedState is CollectionsError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading completed customers: ${completedState.message}',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<CollectionsBloc>().add(
                                          GetCollectionsByTripIdEvent(widget.tripId),
                                        );
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (completedState is CollectionLoadedByTrip) {
                            return CollectionCompletedCustomersTable(
                              tripId: widget.tripId,
                              completedCustomers: completedState.collections,
                              isLoading: false,
                            );
                          }

                          // Default case
                          return const CollectionCompletedCustomersTable(
                            tripId: '',
                            completedCustomers: [],
                            isLoading: true,
                          );
                        },
                      ),

                      // Add some bottom padding
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Select a trip to view collection details'));
        },
      ),
    );
  }
}
