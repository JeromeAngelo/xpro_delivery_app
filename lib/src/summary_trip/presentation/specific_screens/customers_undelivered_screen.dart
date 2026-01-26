import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';

import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

import '../../../../core/common/app/features/trip_ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';

class CustomersUndeliveredScreen extends StatefulWidget {
  final String cancelledInvoiceId;

  const CustomersUndeliveredScreen({
    super.key,
    required this.cancelledInvoiceId,
  });

  @override
  State<CustomersUndeliveredScreen> createState() =>
      _SpecificUndeliveredCustomerScreenState();
}

class _SpecificUndeliveredCustomerScreenState
    extends State<CustomersUndeliveredScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔄 Loading cancelled invoice details for ID: ${widget.cancelledInvoiceId}',
    );

    // Load cancelled invoice by ID using the bloc
    context.read<CancelledInvoiceBloc>().add(
      LoadCancelledInvoicesByIdEvent(widget.cancelledInvoiceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undelivered Customer Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.push('/summary-trip');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // PDF generation logic here
              debugPrint('🖨️ PDF generation requested for cancelled invoice');
            },
          ),
        ],
      ),
      body: BlocListener<CancelledInvoiceBloc, CancelledInvoiceState>(
        listener: (context, state) {
          if (state is CancelledInvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CancelledInvoiceBloc, CancelledInvoiceState>(
          builder: (context, state) {
            debugPrint(
              '📋 Current cancelled invoices state: ${state.runtimeType}',
            );

            if (state is CancelledInvoiceLoading) {
              return const _LoadingWidget();
            }

            if (state is SpecificCancelledInvoiceLoaded) {
              final cancelledInvoice = state.cancelledInvoice;
              debugPrint('✅ Cancelled invoice loaded: ${cancelledInvoice.id}');

              return _buildCancelledInvoiceDetails(context, cancelledInvoice);
            }

            if (state is CancelledInvoiceError) {
              return _ErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<CancelledInvoiceBloc>().add(
                    LoadCancelledInvoicesByIdEvent(widget.cancelledInvoiceId),
                  );
                },
              );
            }

            return const _EmptyWidget();
          },
        ),
      ),
    );
  }

  Widget _buildCancelledInvoiceDetails(BuildContext context, cancelledInvoice) {
    final customer = cancelledInvoice.customer.target;
    final invoices = cancelledInvoice.invoices;
    final deliveryData = cancelledInvoice.deliveryData.target;
   // final trip = cancelledInvoice.trip.target;

    debugPrint('🎯 Cancelled Invoice Details:');
    debugPrint('   📦 Cancelled Invoice ID: ${cancelledInvoice.id}');
    debugPrint('   👤 Customer: ${customer?.name ?? 'Unknown'}');
    debugPrint('   📄 Number of invoices: ${invoices.length}');
    
    // Log individual invoice details
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      debugPrint('   📋 Invoice ${i + 1}: ${invoice.refId ?? invoice.name} - ₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CancelledInvoiceBloc>().add(
          LoadCancelledInvoicesByIdEvent(widget.cancelledInvoiceId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cancellation Summary Card
            _buildCancellationSummaryCard(context, cancelledInvoice),

            const SizedBox(height: 16),

            // Customer Information Card
            if (customer != null) ...[
              _buildCustomerInfoCard(context, customer),
              const SizedBox(height: 16),
            ],

            // Invoices Information Card
            if (invoices.isNotEmpty) ...[
              _buildInvoicesInfoCard(context, invoices),
              const SizedBox(height: 16),
            ],

            // Delivery Information Card
            if (deliveryData != null) ...[
              _buildDeliveryInfoCard(context, deliveryData),
              const SizedBox(height: 16),
            ],

            // Trip Information Card
            // if (trip != null) ...[
            //   _buildTripInfoCard(context, trip),
            //   const SizedBox(height: 16),
            // ],

            // Cancellation Evidence Card
            if (cancelledInvoice.image != null &&
                cancelledInvoice.image!.isNotEmpty) ...[
              _buildEvidenceCard(context, cancelledInvoice),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationSummaryCard(BuildContext context, cancelledInvoice) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cancellation Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Cancellation ID',
              cancelledInvoice.collectionId ?? cancelledInvoice.id ?? 'Unknown',
            ),
            _buildInfoRow(
              'Collection Name',
              cancelledInvoice.collectionName ?? 'Unnamed Cancellation',
            ),
            _buildInfoRow(
              'Undeliverable Reason',
              _getReasonDisplayName(cancelledInvoice.reason),
              isHighlighted: true,
              isError: true,
            ),
            _buildInfoRow('Created', _formatDate(cancelledInvoice.created)),
            _buildInfoRow(
              'Last Updated',
              _formatDate(cancelledInvoice.updated),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCustomerInfoCard(BuildContext context, customer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Store Name', customer.name ?? 'Unknown Store'),
            _buildInfoRow(
              'Address',
              customer.province ?? 'No address provided',
            ),
            _buildInfoRow(
              'Contact Number',
              customer.contactNumber ?? 'No contact',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesInfoCard(BuildContext context, invoices) {
    // Calculate total amount from all invoices
    double totalInvoicesAmount = 0.0;
    if (invoices.isNotEmpty) {
      for (final invoice in invoices) {
        totalInvoicesAmount += invoice.totalAmount ?? 0.0;
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invoices Information',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Number of Invoices',
              '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'}',
            ),
            
            // Show individual invoice details
            ...invoices.asMap().entries.map((entry) {
              final index = entry.key;
              final invoice = entry.value;
              return Column(
                children: [
                  _buildInfoRow(
                    'Invoice ${index + 1}',
                    '${invoice.refId ?? invoice.name ?? 'Unknown'} - ₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                ],
              );
            }),
            
            _buildInfoRow(
              'Total Invoices Amount',
              '₱${totalInvoicesAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(BuildContext context, deliveryData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Delivery Number',
              deliveryData.deliveryNumber ?? 'Unknown',
            ),
            
            if (deliveryData.created != null)
              _buildInfoRow(
                'Delivery Date',
                _formatDate(deliveryData.created),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTripInfoCard(BuildContext context, trip) {
  //   return Card(
  //     elevation: 2,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(
  //                 Icons.route,
  //                 color: Theme.of(context).colorScheme.secondary,
  //                 size: 24,
  //               ),
  //               const SizedBox(width: 8),
  //               Text(
  //                 'Trip Information',
  //                 style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const Divider(height: 24),
  //           _buildInfoRow('Trip Number', trip.tripNumberId ?? 'Unknown'),
  //           _buildInfoRow(
  //             'Status',
  //             trip.isAccepted == true ? 'Accepted' : 'Pending',
  //           ),
  //           _buildInfoRow(
  //             'End Trip',
  //             trip.isEndTrip == true ? 'Completed' : 'In Progress',
  //           ),
  //           if (trip.timeAccepted != null)
  //             _buildInfoRow('Time Accepted', _formatDate(trip.timeAccepted)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEvidenceCard(BuildContext context, cancelledInvoice) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Evidence',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (cancelledInvoice.image != null &&
                cancelledInvoice.image!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    cancelledInvoice.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to view full image',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_photography,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No evidence image available',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isError = false,
  }) {
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    isError
                        ? Theme.of(context).colorScheme.error
                        : isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                fontWeight:
                    isHighlighted || isError
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    isError
                        ? Theme.of(context).colorScheme.error
                        : isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _getReasonDisplayName(UndeliverableReason? reason) {
    if (reason == null) return 'No reason specified';

    switch (reason) {
      case UndeliverableReason.customerNotAvailable:
        return 'Customer Not Available';

      case UndeliverableReason.environmentalIssues:
        return 'Refused Delivery';
      case UndeliverableReason.storeClosed:
        return 'Business Closed';
      case UndeliverableReason.wrongInvoice:
        return 'No Payment';
      case UndeliverableReason.none:
        return 'Damaged Goods';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Loading widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading cancelled invoice details...'),
        ],
      ),
    );
  }
}

// Error widget
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorWidget({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Error Loading Cancelled Invoice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

// Empty widget
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Cancelled Invoice Data',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cancelled invoice details are not available at the moment.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/undelivered-customer-screen');
              },
              child: const Text('Back to Undelivered Customers'),
            ),
          ],
        ),
      ),
    );
  }
}
