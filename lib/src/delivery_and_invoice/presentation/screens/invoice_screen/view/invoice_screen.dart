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
  DeliveryDataState? _cachedState;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      _initializeLocalData();
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
      debugPrint('🔄 Refreshing delivery and invoice data');

      // Refresh delivery data which includes invoice data
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByIdEvent(widget.selectedCustomer!.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listenWhen: (previous, current) => current is DeliveryDataLoaded,
          listener: (context, state) {
            if (state is DeliveryDataLoaded) {
              setState(() {
                _cachedState = state;
              });
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
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DeliveryDataError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      ElevatedButton(
                        onPressed: _initializeLocalData,
                        child: const Text('Retry'),
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
                    child: Text(
                      'Please Wait.......',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
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

              return const Center(
                child: Text(
                  'Select a customer to view invoices',
                  style: TextStyle(fontSize: 16),
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
