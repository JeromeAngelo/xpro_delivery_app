import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class UndeliveredCustomerDashboard extends StatefulWidget {
  const UndeliveredCustomerDashboard({super.key});

  @override
  State<UndeliveredCustomerDashboard> createState() =>
      _UndeliveredCustomerDashboardState();
}

class _UndeliveredCustomerDashboardState
    extends State<UndeliveredCustomerDashboard> {
       UndeliverableCustomerState? _cachedState;
  late final AuthBloc _authBloc;
  late final UndeliverableCustomerBloc _undeliverableCustomerBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _undeliverableCustomerBloc = context.read<UndeliverableCustomerBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      final userId = context.read<UserProvider>().userId;
      if (userId != null) {
        debugPrint('🔄 Loading user trip data for ID: $userId');
        _authBloc
          ..add(LoadLocalUserTripEvent(userId))
          ..add(GetUserTripEvent(userId));
      }

      _authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('✅ User trip loaded: ${state.trip.id}');
          _undeliverableCustomerBloc
            ..add(LoadLocalUndeliverableCustomersEvent(state.trip.id!))
            ..add(GetUndeliverableCustomersEvent(state.trip.id!));
        }
      });

      _isInitialized = true;
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UndeliverableCustomerBloc, UndeliverableCustomerState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),
                _buildDashboardContent(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Undelivered Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text(
                'Undelivered Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, UndeliverableCustomerState state) {
    if (state is UndeliverableCustomerLoaded) {
      final customers = state.customers;

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
            Icons.cancel_outlined,
            customers.length.toString(),
            'Total Undelivered',
          ),
          _buildInfoItem(
            context,
            Icons.calendar_today,
            customers.isNotEmpty
                ? customers.first.time?.toString().split(' ')[0] ?? 'No date'
                : 'No date',
            'Latest Record',
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5, top: 2, bottom: 15),
              child: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)),
                  ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }
}
