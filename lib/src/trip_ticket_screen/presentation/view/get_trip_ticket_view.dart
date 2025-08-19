import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
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
    _loadTripDetails();
  }

  void _loadTripDetails() {
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
          if (state is TripAccepting) {
            context.go('/accepting-trip');
          }

          if (state is TripAccepted && state.trip.id != null) {
            context.read<DeliveryDataBloc>()
              ..add(GetLocalDeliveryDataByIdEvent(state.trip.id!))
              ..add(GetDeliveryDataByIdEvent(state.trip.id!));
            context.go('/checklist');
          }

          // When trip is loaded, start loading delivery data details
          if (state is TripLoaded && state.trip.deliveryData.isNotEmpty) {
            _loadDeliveryDataDetails(state.trip.deliveryData);
          }
        },
        child: BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            // When delivery data is loaded, store it in our map
            if (state is DeliveryDataLoaded && state.deliveryData.id != null) {
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
                      debugPrint('✅ All delivery data loaded successfully');
                    }
                  }
                }
              });
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
                                      horizontal: 10,
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
