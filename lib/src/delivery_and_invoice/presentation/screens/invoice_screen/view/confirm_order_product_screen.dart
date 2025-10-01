import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_product_list.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_summary_order_product_btn.dart';

class ConfirmOrderProductScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final String deliveryDataId;

  const ConfirmOrderProductScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.deliveryDataId,
  });

  @override
  State<ConfirmOrderProductScreen> createState() =>
      _ConfirmOrderProductScreenState();
}

class _ConfirmOrderProductScreenState extends State<ConfirmOrderProductScreen> {
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");
  bool _isDataInitialized = false;
  InvoiceItemsState? _cachedState;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '✅ Order confirmation screen initialized for invoice: ${widget.invoiceNumber}',
      details: 'Invoice ID: ${widget.invoiceId}',
    );
    _loadData();
  }

  void _loadData() {
    if (!_isDataInitialized) {
      debugPrint(
        '🔄 Loading invoice items for confirmation: ${widget.invoiceId}',
      );

      // Load local invoice items first
      context.read<InvoiceItemsBloc>().add(
        GetLocalInvoiceItemsByInvoiceDataIdEvent(widget.invoiceId),
      );

      // Then load from remote
      context.read<InvoiceItemsBloc>().add(
        GetInvoiceItemsByInvoiceDataIdEvent(widget.invoiceId),
      );

      _isDataInitialized = true;
    }
  }

  void _refreshData() {
    debugPrint('🔄 Refreshing invoice items data');
    context.read<InvoiceItemsBloc>().add(
      GetInvoiceItemsByInvoiceDataIdEvent(widget.invoiceId),
    );
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: BlocListener<InvoiceItemsBloc, InvoiceItemsState>(
          listener: (context, state) {
            if (state is InvoiceItemsByInvoiceDataIdLoaded ||
                state is LocalInvoiceItemsByInvoiceDataIdLoaded) {
              setState(() {
                _cachedState = state;
              });
              debugPrint('✅ Invoice items loaded for confirmation');
            }
          },
          child: BlocBuilder<InvoiceItemsBloc, InvoiceItemsState>(
            builder: (context, state) {
              debugPrint(
                '🎯 Building ConfirmOrderProductScreen with state: $state',
              );

              if (state is InvoiceItemsLoading && _cachedState == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is InvoiceItemsError) {
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
              InvoiceItemsState? effectiveState;
              if (state is InvoiceItemsByInvoiceDataIdLoaded &&
                  state.invoiceDataId == widget.invoiceId) {
                effectiveState = state;
              } else if (state is LocalInvoiceItemsByInvoiceDataIdLoaded &&
                  state.invoiceDataId == widget.invoiceId) {
                effectiveState = state;
              } else if (_cachedState is InvoiceItemsByInvoiceDataIdLoaded) {
                final cachedState =
                    _cachedState as InvoiceItemsByInvoiceDataIdLoaded;
                if (cachedState.invoiceDataId == widget.invoiceId) {
                  effectiveState = cachedState;
                }
              } else if (_cachedState
                  is LocalInvoiceItemsByInvoiceDataIdLoaded) {
                final cachedState =
                    _cachedState as LocalInvoiceItemsByInvoiceDataIdLoaded;
                if (cachedState.invoiceDataId == widget.invoiceId) {
                  effectiveState = cachedState;
                }
              }

              if (effectiveState != null) {
                List<dynamic> invoiceItems = [];

                if (effectiveState is InvoiceItemsByInvoiceDataIdLoaded) {
                  invoiceItems = effectiveState.invoiceItems;
                } else if (effectiveState
                    is LocalInvoiceItemsByInvoiceDataIdLoaded) {
                  invoiceItems = effectiveState.invoiceItems;
                }

                debugPrint(
                  '📦 Displaying ${invoiceItems.length} invoice items for confirmation',
                );

                if (invoiceItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please Wait....',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading.....',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
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
                              const SizedBox(height: 80), // Space for button
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ConfirmSummaryOrderProductBtn(
                        deliveryDataId: widget.deliveryDataId,
                        title: 'Total Amount',
                        amount:
                            '₱${_calculateTotal(invoiceItems).toStringAsFixed(2)}',
                      ),
                    ),
                    if (state is InvoiceItemsLoading)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(),
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
      ),
    );
  }
}
