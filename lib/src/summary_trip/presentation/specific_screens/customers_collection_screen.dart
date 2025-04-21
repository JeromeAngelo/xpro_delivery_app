import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';

class CustomersCollectionScreen extends StatefulWidget {
  final String customerId;

  const CustomersCollectionScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomersCollectionScreen> createState() =>
      _CustomersCollectionScreenState();
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _CustomersCollectionScreenState extends State<CustomersCollectionScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context
        .read<CompletedCustomerBloc>()
        .add(GetCompletedCustomerByIdEvent(widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Collection Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go('/summary-trip');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // PDF generation logic
              },
            ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<CompletedCustomerBloc, CompletedCustomerState>(
              listener: (context, state) {
                if (state is CompletedCustomerError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<CompletedCustomerBloc, CompletedCustomerState>(
            builder: (context, completedCustomerState) {
              if (completedCustomerState is CompletedCustomerByIdLoaded) {
                final customer = completedCustomerState.customer;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store Information',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                  'Store Name', customer.storeName ?? ''),
                              _buildInfoRow('Owner', customer.ownerName ?? ''),
                              _buildInfoRow('Address', customer.address ?? ''),
                              _buildInfoRow('Contact',
                                  customer.contactNumber?.first ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Collection Information',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              _buildInfoRow(
                                'Total Amount',
                                '₱${customer.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                              _buildInfoRow(
                                'Payment Mode',
                                customer.paymentSelection
                                    .toString()
                                    .split('.')
                                    .last
                                    .split(RegExp(r'(?=[A-Z])'))
                                    .map((word) => word.capitalize())
                                    .join(' ')
                                    .replaceAll('E Wallet', 'E-Wallet'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (completedCustomerState is CompletedCustomerLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
              textAlign: TextAlign.end,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
