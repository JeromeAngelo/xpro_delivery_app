import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

class EnterCode extends StatefulWidget {
  const EnterCode({super.key});

  @override
  State<EnterCode> createState() => _EnterCodeState();
}

class _EnterCodeState extends State<EnterCode> {
  final _controller = TextEditingController();
  StreamSubscription? _tripSubscription;

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(
            'Enter Trip-Ticket Code',
            style: Theme.of(context).primaryTextTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Search Code',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  errorText: state is TripError ? state.message : null,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
              //  style: ButtonStyle(backgroundColor: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    debugPrint(
                      '🔍 Searching for trip with code: ${_controller.text}',
                    );
                    final tripBloc = context.read<TripBloc>();

                    _tripSubscription?.cancel();
                    _tripSubscription = tripBloc.stream.listen((state) {
                      debugPrint('🔄 Current Trip State: $state');

                      if (state is TripLoaded) {
                        debugPrint('✅ Trip loaded: ${state.trip.id}');
                        debugPrint(
                          '📦 Customers count: ${state.trip.deliveryData.length}',
                        );

                        if (state.trip.id != null) {
                          final customerIds =
                              state.trip.deliveryData
                                  .map((customer) => customer.id ?? '')
                                  .where((id) => id.isNotEmpty)
                                  .toList();

                          debugPrint(
                            '👥 Customer IDs to initialize: $customerIds',
                          );

                          context.read<DeliveryUpdateBloc>().add(
                            InitializePendingStatusEvent(customerIds),
                          );

                          debugPrint(
                            '🔄 Loading customers for trip: ${state.trip.id}',
                          );
                          context.read<DeliveryDataBloc>().add(
                            GetDeliveryDataByTripIdEvent(state.trip.id!),
                          );

                          debugPrint('🚀 Navigating to trip ticket screen');
                          Navigator.pop(context);
                          context.go('/trip-ticket/${_controller.text}');

                          _tripSubscription?.cancel();
                        }
                      } else if (state is TripError) {
                        debugPrint('❌ Trip search error: ${state.message}');
                      }
                    });

                    debugPrint('🔎 Dispatching search event');
                    tripBloc.add(SearchTripEvent(_controller.text));
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
