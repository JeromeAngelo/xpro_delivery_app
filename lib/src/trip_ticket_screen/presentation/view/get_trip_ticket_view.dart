import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/widgets/accept_trip_button.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/widgets/customer_list.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/widgets/dashboard.dart';

class GetTripTickerView extends StatefulWidget {
  const GetTripTickerView({super.key, required this.tripNumber});
  final String tripNumber;

  static const routeName = '/get_trip_ticket';

  @override
  State<GetTripTickerView> createState() => _GetTripTickerViewState();
}

class _GetTripTickerViewState extends State<GetTripTickerView> {
  // Track loaded delivery data
  final Map<String, DeliveryDataEntity> _loadedDeliveryData = {};
  bool _isLoadingDeliveryData = false;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '🎫 Trip Ticket View initialized for trip: ${widget.tripNumber}',
    );
    _loadTripDetails();
  }

  void _loadTripDetails() {
    AppDebugLogger.instance.logInfo(
      '🔍 Loading trip details for: ${widget.tripNumber}',
    );
    context.read<TripBloc>().add(SearchTripEvent(widget.tripNumber));
  }

  // Load delivery data details for all customers in the trip
  void _loadDeliveryDataDetails(List<DeliveryDataEntity> deliveries) {
    if (_isLoadingDeliveryData) return;

    setState(() {
      _isLoadingDeliveryData = true;
    });

    debugPrint(
      '🔄 Loading delivery data details for ${deliveries.length} customers',
    );

    for (var delivery in deliveries) {
      if (delivery.id != null &&
          !_loadedDeliveryData.containsKey(delivery.id)) {
        debugPrint('🔄 Fetching delivery data details for ID: ${delivery.id}');
        context.read<DeliveryDataBloc>().add(
          GetDeliveryDataByIdEvent(delivery.id!),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    AppDebugLogger.instance.logInfo(
      '🔄 User action: Refreshing trip ticket data for: ${widget.tripNumber}',
    );
    _loadTripDetails();
    setState(() {
      _loadedDeliveryData.clear();
      _isLoadingDeliveryData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: BlocListener<TripBloc, TripState>(
        listener: (context, state) {
          AppDebugLogger.instance.logInfo(
            '🎫 Trip state changed: ${state.runtimeType}',
          );

          if (state is TripAccepting) {
            AppDebugLogger.instance.logInfo(
              '🔄 Trip accepting - navigating to accepting screen',
            );
            context.go('/accepting-trip');
          }

          if (state is TripAccepted && state.trip.id != null) {
            AppDebugLogger.instance.logInfo(
              '✅ Trip accepted successfully - ID: ${state.trip.id}',
            );
            context.read<DeliveryDataBloc>()
              ..add(GetLocalDeliveryDataByIdEvent(state.trip.id!))
              ..add(GetDeliveryDataByIdEvent(state.trip.id!));
            context.go('/checklist');
          }

          // When trip is loaded, start loading delivery data details
          if (state is TripLoaded && state.trip.deliveryData.isNotEmpty) {
            AppDebugLogger.instance.logInfo(
              '📋 Trip loaded with ${state.trip.deliveryData.length} delivery items',
            );
            _loadDeliveryDataDetails(state.trip.deliveryData);
          }

          if (state is TripError) {
            AppDebugLogger.instance.logError('❌ Trip error: ${state.message}');
          }
        },
        child: BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            // When delivery data is loaded, store it in our map
            if (state is DeliveryDataLoaded && state.deliveryData.id != null) {
              AppDebugLogger.instance.logInfo(
                '📦 Delivery data loaded for ID: ${state.deliveryData.id}',
              );
              setState(() {
                _loadedDeliveryData[state.deliveryData.id!] =
                    state.deliveryData;

                // Check if we've loaded all delivery data
                if (_isLoadingDeliveryData) {
                  final tripState = context.read<TripBloc>().state;
                  if (tripState is TripLoaded) {
                    final allDeliveryIds =
                        tripState.trip.deliveryData
                            .where((d) => d.id != null)
                            .map((d) => d.id!)
                            .toSet();

                    final loadedIds = _loadedDeliveryData.keys.toSet();

                    if (loadedIds.containsAll(allDeliveryIds)) {
                      _isLoadingDeliveryData = false;
                      AppDebugLogger.instance.logInfo(
                        '✅ All delivery data loaded successfully',
                      );
                      debugPrint('✅ All delivery data loaded successfully');
                    }
                  }
                }
              });
            }

            if (state is DeliveryDataError) {
              AppDebugLogger.instance.logError(
                '❌ Delivery data error: ${state.message}',
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/homepage')),
              title: Text(widget.tripNumber),
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
            body: BlocBuilder<TripBloc, TripState>(
              builder: (context, state) {
                return state is TripLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state is TripError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                    : state is TripLoaded
                    ? Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshData,
                            child: CustomScrollView(
                              slivers: [
                                const SliverToBoxAdapter(
                                  child: TripTicketDashBoard(),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Text(
                                      "Customer List",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: CustomerListTile(
                                    customers: state.trip.deliveryData,
                                    loadedDeliveryData: _loadedDeliveryData,
                                    isLoading: _isLoadingDeliveryData,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AcceptTripButton(tripId: state.trip.id ?? ''),
                      ],
                    )
                    : const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}
