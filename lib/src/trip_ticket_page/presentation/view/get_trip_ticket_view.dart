import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_page/presentation/widgets/accept_trip_button.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_page/presentation/widgets/customer_list.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_page/presentation/widgets/dashboard.dart';


class GetTripTickerView extends StatefulWidget {
  const GetTripTickerView({super.key, required this.tripNumber});
  final String tripNumber;

  static const routeName = '/get_trip_ticket';

  @override
  State<GetTripTickerView> createState() => _GetTripTickerViewState();
}

class _GetTripTickerViewState extends State<GetTripTickerView> {
  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  void _loadTripDetails() {
    context.read<TripBloc>().add(SearchTripEvent(widget.tripNumber));
  }

  Future<void> _refreshData() async {
    _loadTripDetails();
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
            context
                .read<CustomerBloc>()..add(LoadLocalCustomerLocationEvent(state.trip.id!))
                ..add(GetCustomerEvent(state.trip.id!));
            context.go('/checklist');
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => context.go('/homepage'),
            ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
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
                                                horizontal: 10),
                                            child: Text(
                                              "Customer List",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: CustomerListTile(),
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
    );
  }
}
