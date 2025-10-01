import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_button_products.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/product_list.dart';

class ProductListScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final DeliveryDataEntity customer;

  const ProductListScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customer,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isDataInitialized = false;
  InvoiceItemsState? _cachedState;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo(
      '📦 ProductListScreen initialized for invoice: ${widget.invoiceNumber}',
      details: 'Invoice ID: ${widget.invoiceId}, Customer: ${widget.customer.storeName}',
    );
    _loadData();
  }

  void _loadData() {
    if (!_isDataInitialized) {
      debugPrint('🔄 Loading invoice items for invoice: ${widget.invoiceId}');

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoiceNumber}'),
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
            }
          },
          child: BlocBuilder<InvoiceItemsBloc, InvoiceItemsState>(
            builder: (context, state) {
              debugPrint('🎯 Building ProductListScreen with state: $state');

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
                        'Error Loading Items',
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
                  '📦 Displaying ${invoiceItems.length} invoice items',
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
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(10),
                                itemCount: invoiceItems.length,
                                itemBuilder: (context, index) {
                                  final invoiceItem = invoiceItems[index];
                                  return ProductList(
                                    key: ValueKey(invoiceItem.id),
                                    invoiceItem: invoiceItem,
                                    onBaseQuantityChanged: (int baseQuantity) {
                                      debugPrint(
                                        '📝 Base quantity updated for ${invoiceItem.name}: $baseQuantity',
                                      );
                                    },
                                  );
                                },
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
                      child: ConfirmButtonProducts(
                        invoiceId: widget.invoiceId,
                        deliveryDataId: widget.customer.id ?? '',
                        invoiceNumber: widget.invoiceNumber,
                      ),
                    ),
                    if (state is DeliveryDataLoading)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 4,
                          child: const LinearProgressIndicator(),
                        ),
                      ),
                  ],
                );
              }

              return const Center(child: Text('No invoice items available'));
            },
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
