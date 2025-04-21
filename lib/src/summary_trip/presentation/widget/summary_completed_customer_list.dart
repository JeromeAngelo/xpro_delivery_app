import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class SummaryCompletedCustomerList extends StatelessWidget {
  const SummaryCompletedCustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompletedCustomerBloc, CompletedCustomerState>(
      builder: (context, state) {
        if (state is CompletedCustomerLoaded) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.customers.length,
            itemBuilder: (context, index) {
              final customer = state.customers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CommonListTiles(
                  onTap: () {
                    context.push(
                      '/summary-collection/${customer.id}',
                      extra: customer,
                    );
                  },
                  title: customer.storeName ?? 'No Store Name',
                  subtitle: '₱${NumberFormat('#,##0.00').format(customer.totalAmount ?? 0)}',
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.store,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
