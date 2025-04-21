import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

class DeliveryList extends StatelessWidget {
  const DeliveryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is TripLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TripLoaded) {
          final customers = state.trip.customers;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No customers found for this trip',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: customers.map((customer) {
              return _buildDeliveryCard(context, customer);
            }).toList(),
          );
        }

        return const Center(child: Text('No delivery data available'));
      },
    );
  }

  Widget _buildDeliveryCard(BuildContext context, CustomerEntity customer) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Container(
        decoration: _cardDecoration(context),
        child: ListTile(
          leading: _buildLeadingIcon(context),
          title: _buildTitle(context, customer),
          subtitle: _buildSubtitle(context, customer),
          trailing: _buildTrailingIcon(context),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    return Icon(
      Icons.store_rounded,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildTitle(BuildContext context, CustomerEntity customer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        customer.storeName ?? 'No Store Name',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, CustomerEntity customer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        customer.address ?? 'No Address',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildTrailingIcon(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_outlined,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
