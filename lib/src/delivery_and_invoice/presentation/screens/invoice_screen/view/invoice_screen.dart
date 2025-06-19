import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_btn.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/invoice_list.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      _initializeLocalData();
      _hasInitialized = true; // Mark as initialized
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only refresh if we've already initialized and the route is current
    if (_hasInitialized && widget.selectedCustomer != null) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.isActive) {
        debugPrint('🔄 Invoice screen became active, refreshing data...');
        _refreshData();
      }
    }
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint(
        '📱 Loading local data for delivery: ${widget.selectedCustomer!.id}',
      );

      // Load local delivery data which includes invoice information
      context.read<DeliveryDataBloc>().add(
        GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''),
      );

      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
      );

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
        child: BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listenWhen: (previous, current) => current is DeliveryDataLoaded,
          listener: (context, state) {
            if (state is DeliveryDataLoaded) {
              setState(() {
                _cachedState = state;
              });
              debugPrint('✅ Invoice screen: Cached new delivery data state');
            }
          },
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
                final deliveryData = effectiveState.deliveryData;
                final invoice = deliveryData.invoice.target;

                if (invoice == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Please Wait.......',
                          style: TextStyle(fontSize: 16),
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
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: InvoiceList(
                                      deliveryData: deliveryData,
                                      onTap: () {
                                        final route =
                                            '/product-list/${invoice.id}/${invoice.refId ?? invoice.name}';
                                        debugPrint('🚀 Navigating to: $route');
                                        context.push(
                                          route,
                                          extra: widget.selectedCustomer,
                                        );
                                      },
                                    ),
                                  );
                                },
                                childCount:
                                    1, // Single delivery data with its invoice
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ConfirmBtn(
                        invoices: [
                          invoice,
                        ], // Pass the invoice from delivery data
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

  @override
  bool get wantKeepAlive => true;
}
