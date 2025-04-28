import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';

class CustomersDashboardTrx extends StatefulWidget {
  final CustomerEntity customer;

  const CustomersDashboardTrx({super.key, required this.customer});

  @override
  State<CustomersDashboardTrx> createState() => _CustomersDashboardTrxState();
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _CustomersDashboardTrxState extends State<CustomersDashboardTrx> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(
      LoadLocalCustomerLocationEvent(widget.customer.id ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLocationLoaded) {
          return SizedBox(
            height: 180,
            width: double.infinity,
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildLeftColumn(context, state.customer),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            child: _buildRightColumn(context, state.customer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Enhanced loading state with card shape
        return SizedBox(
          height: 180,
          width: double.infinity,
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skeleton for title
                      Container(
                        height: 24,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: Row(
                          children: [
                            // Left column skeleton
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSkeletonRow(),
                                  _buildSkeletonRow(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 50),
                            // Right column skeleton
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSkeletonRow(),
                                  _buildSkeletonRow(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(BuildContext context, CustomerEntity customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.store,
          title: "Store Name",
          value: customer.storeName ?? 'N/A',
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.person,
          title: "Owner Name",
          value: customer.ownerName ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, CustomerEntity customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.payment,
          title: "Mode of Payment",
          value: customer.paymentSelection
              .toString()
              .split('.')
              .last
              .split(RegExp(r'(?=[A-Z])'))
              .map((word) => word.capitalize())
              .join(' ')
              .replaceAll('E Wallet', 'E-Wallet'),
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.attach_money,
          title: "Total Amount",
          value: () {
            debugPrint('💰 Getting confirmed total for ${customer.storeName}');
            final confirmedTotal = customer.confirmedTotalPayment ?? 0.0;
            debugPrint('💵 Final confirmed total: $confirmedTotal');
            return '₱${NumberFormat('#,##0.00').format(confirmedTotal)}';
          }(),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build skeleton loading rows
  Widget _buildSkeletonRow() {
    return Row(
      children: [
        // Icon placeholder
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value placeholder
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              // Title placeholder
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
