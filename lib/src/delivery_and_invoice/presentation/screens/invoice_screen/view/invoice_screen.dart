import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_btn.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/invoice_list.dart';

class InvoiceScreen extends StatefulWidget {
  final CustomerEntity? selectedCustomer;

  const InvoiceScreen({
    super.key,
    this.selectedCustomer,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}
class _InvoiceScreenState extends State<InvoiceScreen> with AutomaticKeepAliveClientMixin {
  bool _isDataInitialized = false;
  InvoiceState? _cachedState;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      _initializeLocalData();
    }
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint('📱 Loading local data for customer: ${widget.selectedCustomer!.id}');
      
      // Load local customer data
      context.read<CustomerBloc>().add(
        LoadLocalCustomerLocationEvent(widget.selectedCustomer!.id ?? '')
      );
      
      // Load local invoices for customer
      context.read<InvoiceBloc>().add(
        LoadLocalInvoicesByCustomerEvent(widget.selectedCustomer!.id ?? '')
      );
      
      _isDataInitialized = true;
    }
  }

  Future<void> _refreshData() async {
    if (widget.selectedCustomer?.id != null) {
      debugPrint('🔄 Refreshing customer and invoice data');
      
      // Refresh customer data
      context.read<CustomerBloc>().add(
        GetCustomerLocationEvent(widget.selectedCustomer!.id!)
      );
      
      // Refresh customer invoices
      context.read<InvoiceBloc>().add(
        GetInvoicesByCustomerEvent(widget.selectedCustomer!.id!)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: MultiBlocListener(
          listeners: [
            BlocListener<CustomerBloc, CustomerState>(
              listenWhen: (previous, current) => 
                current is CustomerLocationLoaded,
              listener: (context, state) {
                if (state is CustomerLocationLoaded) {
                  debugPrint('📍 Customer location loaded');
                }
              },
            ),
            BlocListener<InvoiceBloc, InvoiceState>(
              listenWhen: (previous, current) => 
                current is CustomerInvoicesLoaded,
              listener: (context, state) {
                if (state is CustomerInvoicesLoaded) {
                  setState(() {
                    _cachedState = state;
                  });
                }
              },
            ),
          ],
          child: BlocBuilder<InvoiceBloc, InvoiceState>(
            buildWhen: (previous, current) =>
                current is CustomerInvoicesLoaded || 
                current is InvoiceLoading ||
                current is InvoiceError,
            builder: (context, state) {
              if (state is InvoiceLoading && _cachedState == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is InvoiceError) {
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

              final effectiveState = (state is CustomerInvoicesLoaded) 
                  ? state 
                  : (_cachedState as CustomerInvoicesLoaded?);
              
              if (effectiveState != null && widget.selectedCustomer != null) {
                final customerInvoices = effectiveState.invoices;

                if (customerInvoices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No invoices available for this customer',
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
                                  final invoice = customerInvoices[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: InvoiceList(
                                      invoice: invoice,
                                      onTap: () {
                                        final route = '/product-list/${invoice.id}/${invoice.invoiceNumber}';
                                        context.push(route, extra: widget.selectedCustomer);
                                      },
                                    ),
                                  );
                                },
                                childCount: customerInvoices.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ConfirmBtn(
                        invoices: customerInvoices,
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
