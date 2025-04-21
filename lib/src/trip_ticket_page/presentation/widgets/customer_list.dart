import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

class CustomerListTile extends StatefulWidget {
  const CustomerListTile({super.key});

  @override
  State<CustomerListTile> createState() => _CustomerListTileState();
}

class _CustomerListTileState extends State<CustomerListTile> {
  @override
  void initState() {
    super.initState();
    final tripState = context.read<TripBloc>().state;
    if (tripState is TripLoaded) {
      final customers = tripState.trip.customers;
      for (var customer in customers) {
        context
            .read<CustomerBloc>()
            .add(GetCustomerLocationEvent(customer.id ?? ''));
            }
        }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is! TripLoaded) {
          return const SizedBox();
        }

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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfo(context, customer),
                    const SizedBox(height: 16),
                    _buildDeliveryStatus(context, customer),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerInfo(BuildContext context, CustomerEntity customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          context,
          Icons.store,
          customer.storeName ?? 'No Store Name',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.person,
          customer.ownerName ?? 'No Owner Name',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.location_on,
          '${customer.address},',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.attach_money,
          '₱${customer.totalAmount!.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          Icons.payment,
          customer.modeOfPayment ?? '',
        ),
      ],
    );
  }
Widget _buildDeliveryStatus(BuildContext context, CustomerEntity customer) {
  return BlocBuilder<CustomerBloc, CustomerState>(
    builder: (context, state) {
      // Force refresh customer location data
      if (state is! CustomerLocationLoaded) {
        context.read<CustomerBloc>().add(GetCustomerLocationEvent(customer.id!));
      }

      String status = customer.deliveryStatus.isNotEmpty
          ? customer.deliveryStatus.last.title ?? "No Status"
          : "No Status";

      print('Initial Status: $status');
      print('Delivery Status List: ${customer.deliveryStatus.map((d) => d.title).toList()}');

      if (state is CustomerLocationLoaded && state.customer.id == customer.id) {
        status = state.customer.deliveryStatus.isNotEmpty
            ? state.customer.deliveryStatus.last.title ?? "No Status"
            : "No Status";
        print('Updated Status from State: $status');
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Status:",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.outline,
                size: 16,
              ),
            ],
          ),
        ],
      );
    },
  );
}


  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    TextStyle? style,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: style ?? Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        )
      ],
    );
  }
}
