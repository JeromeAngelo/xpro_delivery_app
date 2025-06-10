import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_product_list.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_summary_order_product_btn.dart';

class ConfirmOrderProductScreen extends StatefulWidget {
  final String deliveryDataId;
  final String invoiceNumber;

  const ConfirmOrderProductScreen({
    super.key,
    required this.deliveryDataId,
    required this.invoiceNumber,
  });

  @override
  State<ConfirmOrderProductScreen> createState() =>
      _ConfirmOrderProductScreenState();
}

class _ConfirmOrderProductScreenState extends State<ConfirmOrderProductScreen> {
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");
  bool _isDataInitialized = false;
  DeliveryDataState? _cachedState;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isDataInitialized) {
      debugPrint(
        '🔄 Loading delivery data for confirmation: ${widget.deliveryDataId}',
      );

      // Load local delivery data first
      context.read<DeliveryDataBloc>().add(
        GetLocalDeliveryDataByIdEvent(widget.deliveryDataId),
      );

      // Then load from remote
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByIdEvent(widget.deliveryDataId),
      );

      _isDataInitialized = true;
    }
  }

  double _calculateTotal(List<dynamic> invoiceItems) {
    double total = 0.0;
    debugPrint(
      '🧮 Starting total calculation for ${invoiceItems.length} items',
    );

    for (var item in invoiceItems) {
      // Get the total amount directly from the invoice item entity
      final itemTotalAmount = item.totalAmount ?? 0.0;
      total += itemTotalAmount;

      debugPrint('💰 Item: ${item.name}');
      debugPrint('   Total Amount: ₱${itemTotalAmount.toStringAsFixed(2)}');
    }

    debugPrint('💰 Final calculated total: ₱${total.toStringAsFixed(2)}');
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Invoice #${widget.invoiceNumber}'),
        centerTitle: true,
      ),
      // Add this import at the top

      // Replace the existing body structure (around lines 80-150) with:
      body: BlocListener<DeliveryDataBloc, DeliveryDataState>(
        listener: (context, state) {
          if (state is DeliveryDataLoaded) {
            setState(() {
              _cachedState = state;
            });
            debugPrint('✅ Delivery data loaded for confirmation');
          }
        },
        child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
          builder: (context, state) {
            debugPrint(
              '🎯 Building ConfirmOrderProductScreen with state: $state',
            );

            if (state is DeliveryDataLoading && _cachedState == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeliveryDataError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Order',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Determine effective state
            DeliveryDataState? effectiveState;
            if (state is DeliveryDataLoaded) {
              effectiveState = state;
            } else if (_cachedState is DeliveryDataLoaded) {
              effectiveState = _cachedState;
            }

            if (effectiveState is DeliveryDataLoaded) {
              final deliveryData = effectiveState.deliveryData;
              final invoiceItems = deliveryData.invoiceItems;

              if (invoiceItems.isEmpty) {
                return const Center(child: Text('Please Wait.......'));
              }

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order Confirmation',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 10),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: invoiceItems.length,
                                          itemBuilder: (context, index) {
                                            return ConfirmProductList(
                                              invoiceItem: invoiceItems[index],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Space for button
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        ConfirmSummaryOrderProductBtn(
                          deliveryDataId: widget.deliveryDataId,
                          title: 'Total Amount',
                          amount:
                              '₱${_calculateTotal(invoiceItems).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading order details...'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
