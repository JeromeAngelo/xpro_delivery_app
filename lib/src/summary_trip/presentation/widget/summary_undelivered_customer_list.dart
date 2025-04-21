import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class SummaryUndeliveredCustomerList extends StatelessWidget {
  const SummaryUndeliveredCustomerList({super.key});

  String _formatTimeAndReason(String? reason, DateTime? time) {
    final dateStr = time?.toString().split(' ')[0] ?? 'No date';
    final formattedReason = reason
            ?.split('.')
            .last
            .replaceAllMapped(
                RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
            .trim() ??
        'No reason';
    return '$formattedReason - $dateStr';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UndeliverableCustomerBloc, UndeliverableCustomerState>(
      builder: (context, state) {
        if (state is UndeliverableCustomerLoaded) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.customers.length,
            itemBuilder: (context, index) {
              final customer = state.customers[index];
              final subtitle = _formatTimeAndReason(
                customer.reason.toString().split('.').last,
                customer.time,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CommonListTiles(
                  onTap: () {
                    context.push(
                      '/undelivered-details/${customer.customer?.id}',
                      extra: customer,
                    );
                  },
                  title: customer.customer?.storeName ?? 'No Store Name',
                  subtitle: subtitle,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.cancel_outlined,
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
