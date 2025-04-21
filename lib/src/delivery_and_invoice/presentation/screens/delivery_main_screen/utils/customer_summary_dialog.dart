import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';

class CustomerSummaryDialog extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerSummaryDialog({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final latestTime = state is CustomerTotalTimeCalculated
            ? state.totalTime
            : customer.totalTime ?? '0h 0m 0s';

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delivery Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.store,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(customer.storeName ?? 'N/A'),
                  subtitle: const Text('Store Name'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(latestTime),
                  subtitle: const Text('Total Delivery Time'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('${customer.numberOfInvoices ?? 0}'),
                  subtitle: const Text('Total Invoices'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.pushReplacement('/delivery-and-timeline'),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
