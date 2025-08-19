import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_state.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_btn.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';

class InvoiceScreen extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const InvoiceScreen({super.key, this.selectedCustomer});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isDataInitialized = false;
  bool _hasInitialized = false; // Add this flag to track initialization
  DeliveryDataState? _cachedState;
  
  // Cache for invoice item counts to avoid repeated loading
  final Map<String, int> _invoiceItemCounts = {};
  final Set<String> _loadingInvoiceIds = {};

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo('📋 InvoiceScreen initialized');
    
    if (widget.selectedCustomer != null) {
      AppDebugLogger.instance.logInfo(
        '📋 Loading invoices for customer: ${widget.selectedCustomer!.storeName ?? 'Unknown'}',
        details: 'Customer ID: ${widget.selectedCustomer!.id}',
      );
      _initializeLocalData();
      _hasInitialized = true; // Mark as initialized
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Disable auto-refresh to prevent interference with router data loading
    // Data will be loaded by the router when navigating to this screen
    debugPrint('📋 InvoiceScreen: didChangeDependencies called, but auto-refresh disabled');
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint(
        '📱 InvoiceScreen: Customer data received via navigation: ${widget.selectedCustomer!.id}',
      );

      // Data loading is already handled by the router/navigation flow
      // No need to load data again here to prevent multiple loading states
      debugPrint('📱 InvoiceScreen: Using customer data from navigation, skipping data load');

      _isDataInitialized = true;
    }
  }

  Future<void> _refreshData() async {
    if (widget.selectedCustomer?.id != null) {
      debugPrint(
        '🔄 Refreshing delivery and invoice data for customer: ${widget.selectedCustomer!.id}',
      );

      final deliveryDataBloc = context.read<DeliveryDataBloc>();

      // Load both local and remote data for fresh information
      deliveryDataBloc
        ..add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''))
        ..add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!));
    }
  }

  // Add manual refresh method for pull-to-refresh
  Future<void> _handleManualRefresh() async {
    debugPrint('🔄 Manual refresh triggered for invoice screen');
    await _refreshData();

    // Add a small delay to ensure smooth refresh animation
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleManualRefresh, // Add pull-to-refresh functionality
        child: MultiBlocListener(
          listeners: [
            BlocListener<DeliveryDataBloc, DeliveryDataState>(
              listenWhen: (previous, current) => 
                  current is DeliveryDataLoaded || 
                  current is InvoiceSetToUnloading ||
                  current is InvoiceSetToUnloaded,
              listener: (context, state) {
                if (state is DeliveryDataLoaded) {
                  setState(() {
                    _cachedState = state;
                  });
                  debugPrint('✅ Invoice screen: Cached new delivery data state');
                  debugPrint('   📋 Invoices count: ${state.deliveryData.invoices.length}');
                  debugPrint('   📦 Invoice items count: ${state.deliveryData.invoiceItems.length}');
                  
                  // Load accurate item counts for each invoice
                  _loadInvoiceItemCounts(state.deliveryData.invoices);
                } else if (state is InvoiceSetToUnloading || state is InvoiceSetToUnloaded) {
                  debugPrint('🔄 Invoice status changed, data should be refreshed automatically');
                }
              },
            ),
            BlocListener<InvoiceItemsBloc, InvoiceItemsState>(
              listener: (context, state) {
                if (state is InvoiceItemsByInvoiceDataIdLoaded) {
                  debugPrint('✅ Invoice items loaded for invoice: ${state.invoiceDataId}');
                  debugPrint('   📦 Items count: ${state.invoiceItems.length}');
                  
                  setState(() {
                    _invoiceItemCounts[state.invoiceDataId] = state.invoiceItems.length;
                    _loadingInvoiceIds.remove(state.invoiceDataId);
                  });
                } else if (state is InvoiceItemsError) {
                  debugPrint('❌ Error loading invoice items: ${state.message}');
                  // Remove from loading set on error
                  setState(() {
                    _loadingInvoiceIds.clear();
                  });
                }
              },
            ),
          ],
          child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
            buildWhen:
                (previous, current) =>
                    current is DeliveryDataLoaded ||
                    current is DeliveryDataLoading ||
                    current is DeliveryDataError,
            builder: (context, state) {
              if (state is DeliveryDataLoading && _cachedState == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading invoice data...'),
                    ],
                  ),
                );
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
                        'Error loading invoice data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          debugPrint(
                            '🔄 Retry button pressed, refreshing data...',
                          );
                          _refreshData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final effectiveState =
                  (state is DeliveryDataLoaded)
                      ? state
                      : (_cachedState as DeliveryDataLoaded?);

              if (effectiveState != null && widget.selectedCustomer != null) {
                // Use loaded data if it has valid ID, otherwise use selectedCustomer
                final deliveryData = (effectiveState.deliveryData.id != null) 
                    ? effectiveState.deliveryData 
                    : widget.selectedCustomer!;
                debugPrint('📱 InvoiceScreen: Using delivery data with ID: ${deliveryData.id}');
                
                final invoices = deliveryData.invoices;
                debugPrint('📊 Invoice Analysis:');
                debugPrint('   📋 Total invoices: ${invoices.length}');
                debugPrint('   📦 Total invoice items: ${deliveryData.invoiceItems.length}');
                
                // Debug each invoice and validate item relationships
                _validateInvoiceItemRelationships(deliveryData, invoices);

                if (invoices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No invoices available',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This delivery has no associated invoices',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(10),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final invoice = invoices[index];
                                  final invoiceId = invoice.id as String;
                                  
                                  // Get accurate item count from cache or show loading
                                  final itemCount = _invoiceItemCounts[invoiceId];
                                  final isLoading = _loadingInvoiceIds.contains(invoiceId);
                                  
                                  debugPrint('📋 Invoice ${index + 1} "${invoice.refId ?? invoice.name}":');
                                  debugPrint('   🆔 Invoice ID: $invoiceId');
                                  debugPrint('   📦 Cached items count: ${itemCount ?? 'Loading...'}');
                                  debugPrint('   ⏳ Is loading: $isLoading');
                                  debugPrint('   💰 Total amount: ₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}');
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: _buildInvoiceListTile(
                                      deliveryData: deliveryData,
                                      invoice: invoice,
                                      itemCount: itemCount,
                                      isLoading: isLoading,
                                      onTap: () {
                                        final route =
                                            '/product-list/${invoice.id}/${invoice.refId ?? invoice.name}';
                                        AppDebugLogger.instance.logNavigation(
                                          '/invoice', 
                                          route, 
                                          reason: 'Invoice ${invoice.refId ?? invoice.name} selected'
                                        );
                                        context.push(
                                          route,
                                          extra: widget.selectedCustomer,
                                        );
                                      },
                                    ),
                                  );
                                },
                                childCount: invoices.length, // Multiple invoices
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ConfirmBtn(
                        invoices: invoices.toList(), // Pass all invoices from delivery data
                        customer: widget.selectedCustomer!,
                      ),
                    ),
                  ],
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select a customer to view invoices',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a customer from the delivery list',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _loadInvoiceItemCounts(dynamic invoices) {
    debugPrint('📊 Loading accurate invoice item counts using InvoiceItemsBloc');
    
    for (var invoice in invoices) {
      final invoiceId = invoice.id as String;
      
      // Skip if already loaded or currently loading
      if (_invoiceItemCounts.containsKey(invoiceId) || _loadingInvoiceIds.contains(invoiceId)) {
        debugPrint('   ⏭️ Skipping invoice $invoiceId - already loaded/loading');
        continue;
      }
      
      debugPrint('   📡 Loading items for invoice: $invoiceId');
      _loadingInvoiceIds.add(invoiceId);
      
      // Load invoice items using InvoiceItemsBloc
      context.read<InvoiceItemsBloc>().add(
        GetInvoiceItemsByInvoiceDataIdEvent(invoiceId),
      );
    }
  }

  Widget _buildInvoiceListTile({
    required DeliveryDataEntity deliveryData,
    required dynamic invoice,
    required int? itemCount,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    // Get invoice status
    final invoiceStatus = _getInvoiceStatus(deliveryData);
    
    // Display count with loading indicator if needed
    String itemDisplay;
    if (isLoading) {
      itemDisplay = 'Loading...';
    } else if (itemCount != null) {
      itemDisplay = '$itemCount Products';
    } else {
      itemDisplay = '? Products';
    }

    return CommonListTiles(
      title: 'Invoice #${invoice.refId ?? invoice.name ?? 'Unknown'}',
      subtitle: '$itemDisplay | ${invoiceStatus.toUpperCase()}',
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.receipt_long,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      onTap: onTap,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  String _getInvoiceStatus(DeliveryDataEntity deliveryData) {
    final invoiceStatus = deliveryData.invoiceStatus;
    
    if (invoiceStatus != null) {
      switch (invoiceStatus) {
        case InvoiceStatus.none:
          return 'Pending';
        case InvoiceStatus.truck:
          return 'In Transit';
        case InvoiceStatus.unloading:
          return 'Unloading';
        case InvoiceStatus.unloaded:
          return 'Unloaded';
        case InvoiceStatus.delivered:
          return 'Delivered';
        case InvoiceStatus.cancelled:
          return 'Cancelled';
      }
    }
    
    // Fallback status determination
    if (deliveryData.hasTrip == true) {
      return 'In Transit';
    }
    
    return 'Ready for Delivery';
  }

  void _validateInvoiceItemRelationships(DeliveryDataEntity deliveryData, dynamic invoices) {
    debugPrint('🔍 Validating invoice-item relationships:');
    
    // Track items without proper invoice relationships
    int orphanedItems = 0;
    List<String> invoiceIds = invoices.map<String>((inv) => inv.id as String).toList();
    
    debugPrint('   📋 Invoice IDs: $invoiceIds');
    
    for (int i = 0; i < deliveryData.invoiceItems.length; i++) {
      final item = deliveryData.invoiceItems[i];
      final itemInvoiceId = item.invoiceData.target?.id ?? item.invoiceDataId;
      
      if (itemInvoiceId == null || !invoiceIds.contains(itemInvoiceId)) {
        orphanedItems++;
        debugPrint('   ⚠️ Orphaned item: "${item.name}" (Invoice ID: $itemInvoiceId)');
      }
    }
    
    // Debug each invoice and its items
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final itemsForThisInvoice = deliveryData.invoiceItems.where((item) {
        final itemInvoiceId = item.invoiceData.target?.id ?? item.invoiceDataId;
        return itemInvoiceId == invoice.id;
      }).toList();
      
      debugPrint('   📋 Invoice ${i + 1}: ${invoice.refId ?? invoice.name}');
      debugPrint('      📦 Items count: ${itemsForThisInvoice.length}');
      debugPrint('      💰 Total amount: ₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}');
      
      // Debug individual items
      for (var item in itemsForThisInvoice) {
        debugPrint('         - ${item.name} (Qty: ${item.quantity})');
      }
    }
    
    if (orphanedItems > 0) {
      debugPrint('⚠️ WARNING: $orphanedItems items are not properly linked to invoices');
    }
    
    debugPrint('✅ Invoice validation complete');
  }

  @override
  bool get wantKeepAlive => true;
}
