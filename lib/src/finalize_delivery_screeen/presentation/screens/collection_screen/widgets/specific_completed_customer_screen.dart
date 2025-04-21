import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_state.dart';

class CompletedCustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CompletedCustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CompletedCustomerDetailsScreen> createState() =>
      _CompletedCustomerDetailsScreenState();
}

class _CompletedCustomerDetailsScreenState
    extends State<CompletedCustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<CompletedCustomerBloc>()
        .add(GetCompletedCustomerByIdEvent(widget.customerId));

    context
        .read<TransactionBloc>()
        .add(GetTransactionsByCompletedCustomerEvent(widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.push('/collection-screen');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // PDF generation logic here
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
          BlocListener<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionError) {
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
                    // Store Info Card
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
                            _buildInfoRow(
                                'Contact', customer.contactNumber?.first ?? ''),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (context, transactionState) {
                        if (transactionState is TransactionsLoaded) {
                          final transaction =
                              transactionState.transactions.firstOrNull;

                          debugPrint('🎯 Transaction State Details:');
                          debugPrint('   📋 Full Transaction: $transaction');
                          debugPrint(
                              '   📅 Transaction Date: ${transaction?.transactionDate}');
                          debugPrint(
                              '   📊 Transactions Length: ${transactionState.transactions.length}');
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Collection Information',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    'Total Amount',
                                    '₱${double.tryParse(transaction?.totalAmount.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                  ),
                                  _buildInfoRow(
                                    'Payment Mode',
                                    transaction?.modeOfPayment
                                            .toString()
                                            .split('.')
                                            .last
                                            .replaceAllMapped(
                                              RegExp(r'([A-Z][a-z]+)'),
                                              (match) =>
                                                  '${match.group(1)?[0].toUpperCase()}${match.group(1)?.substring(1)}',
                                            )
                                            .replaceAllMapped(
                                              RegExp(r'([a-z])([A-Z])'),
                                              (match) =>
                                                  '${match.group(1)} ${match.group(2)}',
                                            ) ??
                                        '',
                                  ),
                                  _buildInfoRow(
                                    'Reference Number',
                                    transaction?.refNumber?.toString() ?? 'N/A',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),

                    const SizedBox(height: 16),

                    // Invoices Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoices',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: customer.invoices.length,
                              itemBuilder: (context, index) {
                                final invoice = customer.invoices[index];
                                return ListTile(
                                  title:
                                      Text('Invoice #${invoice.invoiceNumber}'),
                                  subtitle: Text(
                                      '₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}'),
                                );
                              },
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
