import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/presentation/bloc/collections_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_collection/presentation/bloc/collections_state.dart';

class CompletedCustomerDetailsScreen extends StatefulWidget {
  final String collectionId;

  const CompletedCustomerDetailsScreen({super.key, required this.collectionId});

  @override
  State<CompletedCustomerDetailsScreen> createState() =>
      _CompletedCustomerDetailsScreenState();
}

class _CompletedCustomerDetailsScreenState
    extends State<CompletedCustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔄 Loading collection details for ID: ${widget.collectionId}');

    // Load collection by ID using the new bloc
    context.read<CollectionsBloc>().add(
      GetCollectionByIdEvent(widget.collectionId),
    );
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
              debugPrint('🖨️ PDF generation requested');
            },
          ),
        ],
      ),
      body: BlocListener<CollectionsBloc, CollectionsState>(
        listener: (context, state) {
          if (state is CollectionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<CollectionsBloc, CollectionsState>(
          builder: (context, state) {
            debugPrint('📋 Current collections state: ${state.runtimeType}');

            if (state is CollectionsLoading) {
              return const _LoadingWidget();
            }

            if (state is CollectionLoaded) {
              final collection = state.collection;
              debugPrint('✅ Collection loaded: ${collection.id}');

              return _buildCollectionDetails(context, collection);
            }

            if (state is CollectionsError) {
              return _ErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<CollectionsBloc>().add(
                    GetCollectionByIdEvent(widget.collectionId),
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

  Widget _buildCollectionDetails(BuildContext context, collection) {
    final customer = collection.customer.target;
    final invoices = collection.invoices;
    final deliveryData = collection.deliveryData.target;
    final trip = collection.trip.target;

    debugPrint('🎯 Collection Details:');
    debugPrint('   📦 Collection ID: ${collection.id}');
    debugPrint('   👤 Customer: ${customer?.name ?? 'Unknown'}');
    debugPrint('   💰 Collection Total Amount: ${collection.totalAmount}');
    debugPrint('   📄 Number of invoices: ${invoices.length}');

    // Log individual invoice details
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      debugPrint(
        '   📋 Invoice ${i + 1}: ${invoice.refId ?? invoice.name} - ₱${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CollectionsBloc>().add(
          GetCollectionByIdEvent(widget.collectionId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection Summary Card
            _buildCollectionSummaryCard(
              context,
              collection,
              customer,
              deliveryData,
            ),

            const SizedBox(height: 16),

            // Customer Information Card
            if (customer != null) ...[
              _buildCustomerInfoCard(context, customer),
              const SizedBox(height: 16),
            ],

            // Invoices Information Card
            if (invoices.isNotEmpty) ...[
              _buildInvoicesInfoCard(context, invoices, collection),
              const SizedBox(height: 16),
            ],

            // Trip Information Card
            if (trip != null) ...[_buildTripInfoCard(context, trip)],
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionSummaryCard(
    BuildContext context,
    collection,
    customer,
    deliveryData,
  ) {
    // Calculate total amount from all invoices
    final invoices = collection.invoices;
    double totalInvoicesAmount = 0.0;
    if (invoices.isNotEmpty) {
      for (final invoice in invoices) {
        totalInvoicesAmount += invoice.totalAmount ?? 0.0;
      }
    }

    // Use invoices total or fallback to collection total
    final displayAmount =
        totalInvoicesAmount > 0.0
            ? totalInvoicesAmount
            : (collection.totalAmount ?? 0.0);
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
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Collection Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Delivery Number',
              deliveryData.deliveryNumber ?? 'Unknown Store',
            ),

            _buildInfoRow(
              'Total Amount',
              '₱${displayAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
            _buildInfoRow(
              'Payment Mode',
              customer.paymentMode ?? 'Unknown Store',
            ),

            _buildInfoRow('Created', _formatDate(collection.created)),
            _buildInfoRow('Last Updated', _formatDate(collection.updated)),
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
            _buildInfoRow('Owner Name', customer.ownerName ?? 'Unknown Owner'),
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

  Widget _buildInvoicesInfoCard(BuildContext context, invoices, collection) {
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

  Widget _buildTripInfoCard(BuildContext context, trip) {
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
                  Icons.route,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trip Information',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Trip Number', trip.tripNumberId ?? 'Unknown'),
            _buildInfoRow(
              'Status',
              trip.isAccepted == true ? 'Accepted' : 'Pending',
            ),
            _buildInfoRow(
              'End Trip',
              trip.isEndTrip == true ? 'Completed' : 'In Progress',
            ),
            if (trip.timeAccepted != null)
              _buildInfoRow('Time Accepted', _formatDate(trip.timeAccepted)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
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
                    isHighlighted
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
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color:
                    isHighlighted
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
          Text('Loading collection details...'),
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
              'Error Loading Collection',
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
              'No Collection Data',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Collection details are not available at the moment.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/collection-screen');
              },
              child: const Text('Back to Collections'),
            ),
          ],
        ),
      ),
    );
  }
}
