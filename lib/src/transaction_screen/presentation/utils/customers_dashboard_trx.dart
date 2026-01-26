import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
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

      context.read<DeliveryDataBloc>().add(
            GetDeliveryDataByIdEvent(widget.deliveryData.id!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        DeliveryDataEntity effectiveDeliveryData;

        if (state is DeliveryDataLoaded) {
          effectiveDeliveryData = state.deliveryData;
          debugPrint('✅ Using loaded delivery data from bloc');
        } else {
          effectiveDeliveryData = widget.deliveryData;
          debugPrint('📦 Using initial delivery data from widget');
        }

        // ✅ Use DeliveryData fields directly (no customer.target)
        final storeName = (effectiveDeliveryData.storeName ?? '').trim();
        final address = (effectiveDeliveryData.municipality ?? '').trim();
        final mop = (effectiveDeliveryData.paymentMode ?? '').trim();

        final hasAnyCustomerInfo =
            storeName.isNotEmpty || address.isNotEmpty || mop.isNotEmpty;

        if (hasAnyCustomerInfo) {
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
                              effectiveDeliveryData,
                            ),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            child: _buildRightColumn(
                              context,
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
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(),
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

  Widget _buildLeftColumn(BuildContext context, DeliveryDataEntity deliveryData) {
    final storeName = (deliveryData.storeName ?? '').trim();
    final address = (deliveryData.municipality ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.store,
          title: "Store Name",
          value: storeName.isEmpty ? 'N/A' : storeName,
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.location_on,
          title: "Address",
          value: address.isEmpty ? 'N/A' : address,
        ),
      ],
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    DeliveryDataEntity deliveryData,
  ) {
    final mop = (deliveryData.paymentMode ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icons.payment,
          title: "Mode of Payment",
          value: mop.isEmpty ? 'N/A' : mop,
        ),
        _buildInfoRow(
          context: context,
          icon: Icons.attach_money,
          title: "Total Amount",
          value: _calculateTotalAmountFromInvoices(deliveryData),
        ),
      ],
    );
  }

  /// ✅ Sum ALL invoices totalAmount from deliveryData.invoices
  /// Shows as "balance"
  String _calculateTotalAmountFromInvoices(DeliveryDataEntity deliveryData) {
    debugPrint('💰 [BALANCE] Calculating total from invoices for delivery=${deliveryData.id}');

    double total = 0.0;

    final invoices = deliveryData.invoices;

    debugPrint('🧾 [BALANCE] invoices count=${invoices.length}');

    for (final inv in invoices) {
      final amt = (inv.totalAmount ?? 0.0);
      total += amt;

      debugPrint(
        '   • invoiceId=${inv.id} | totalAmount=${amt.toStringAsFixed(2)}',
      );
    }

    debugPrint('✅ [BALANCE] total sum=₱${total.toStringAsFixed(2)}');

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
