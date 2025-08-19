import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class CustomersDashboardTrx extends StatefulWidget {
  final DeliveryDataEntity deliveryData;

  const CustomersDashboardTrx({super.key, required this.deliveryData});

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
    _loadDeliveryData();
  }

  void _loadDeliveryData() {
    if (widget.deliveryData.id != null) {
      debugPrint(
        '🔄 Loading delivery data for transaction: ${widget.deliveryData.id}',
      );

      // Load local data first
      context.read<DeliveryDataBloc>().add(
        GetLocalDeliveryDataByIdEvent(widget.deliveryData.id!),
      );

      // Then load from remote
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByIdEvent(widget.deliveryData.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        DeliveryDataEntity? effectiveDeliveryData;

        if (state is DeliveryDataLoaded) {
          effectiveDeliveryData = state.deliveryData;
          debugPrint('✅ Using loaded delivery data from bloc');
        } else {
          effectiveDeliveryData = widget.deliveryData;
          debugPrint('📦 Using initial delivery data from widget');
        }

        final customer = effectiveDeliveryData.customer.target;

        if (customer != null) {
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
                            child: _buildLeftColumn(
                              context,
                              customer,
                              effectiveDeliveryData,
                            ),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            child: _buildRightColumn(
                              context,
                              customer,
                              effectiveDeliveryData,
                            ),
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
                  if (state is DeliveryDataLoading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 2,
                        child: const LinearProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(
    BuildContext context,
    dynamic customer,
    DeliveryDataEntity deliveryData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.store,
          title: "Store Name",
          value: customer.name ?? customer.name ?? 'N/A',
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.person,
          title: "Address",
          value: customer.province ?? customer.province ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    dynamic customer,
    DeliveryDataEntity deliveryData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.payment,
          title: "Mode of Payment",
          value: customer.paymentMode ?? customer.paymentMode ?? 'N/A',
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.attach_money,
          title: "Total Amount",
          value: _calculateTotalAmount(deliveryData),
        ),
      ],
    );
  }

  // String _getPaymentModeDisplay(dynamic paymentSelection) {
  //   if (paymentSelection == null) return 'N/A';

  //   return paymentSelection
  //       .toString()
  //       .split('.')
  //       .last
  //       .split(RegExp(r'(?=[A-Z])'))
  //       .map((word) => word.capitalize())
  //       .join(' ')
  //       .replaceAll('E Wallet', 'E-Wallet');
  // }

  String _calculateTotalAmount(DeliveryDataEntity deliveryData) {
    debugPrint('💰 Calculating total amount for delivery: ${deliveryData.id}');

    double total = 0.0;

    // Use invoices relation for total amount calculation
    if (deliveryData.invoices.isNotEmpty) {
      for (var invoice in deliveryData.invoices) {
        final invoiceTotal = invoice.totalAmount ?? 0.0;
        total += invoiceTotal;
        debugPrint(
          '   📄 Invoice: ${invoice.id} - Amount: ₱${invoiceTotal.toStringAsFixed(2)}',
        );
      }
      debugPrint('💵 Total from invoices: ₱${total.toStringAsFixed(2)}');
    } else {
      // Fallback to single invoice relation if invoices collection is empty
      final invoice = deliveryData.invoice.target;
      if (invoice != null && invoice.totalAmount != null) {
        total = invoice.totalAmount!;
        debugPrint(
          '   📄 Using single invoice total: ₱${total.toStringAsFixed(2)}',
        );
      } else {
        // Last fallback to invoice items if both invoice relations are unavailable
        final invoiceItems = deliveryData.invoiceItems;
        if (invoiceItems.isNotEmpty) {
          for (var item in invoiceItems) {
            final itemTotal = item.totalAmount ?? 0.0;
            total += itemTotal;
            debugPrint(
              '   📦 Item: ${item.name} - Amount: ₱${itemTotal.toStringAsFixed(2)}',
            );
          }
          debugPrint(
            '💵 Total from invoice items: ₱${total.toStringAsFixed(2)}',
          );
        }
      }
    }

    debugPrint('💵 Final total amount: ₱${total.toStringAsFixed(2)}');
    return '₱${NumberFormat('#,##0.00').format(total)}';
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
