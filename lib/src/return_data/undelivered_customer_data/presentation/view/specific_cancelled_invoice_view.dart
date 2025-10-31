import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/return_data/undelivered_customer_data/presentation/widgets/specific_cancelled_invoice_widgets/specific_cancelled_invoice_dashboard.dart';
import 'package:xpro_delivery_admin_app/src/return_data/undelivered_customer_data/presentation/widgets/specific_cancelled_invoice_widgets/ci_invoice_items_table.dart';

import '../widgets/specific_cancelled_invoice_widgets/specific_cancelled_invoice_header.dart';

class SpecificCancelledInvoiceView extends StatefulWidget {
  final String cancelledInvoiceId;

  const SpecificCancelledInvoiceView({
    super.key,
    required this.cancelledInvoiceId,
  });

  @override
  State<SpecificCancelledInvoiceView> createState() =>
      _SpecificCancelledInvoiceViewState();
}

class _SpecificCancelledInvoiceViewState
    extends State<SpecificCancelledInvoiceView> {
  @override
  void initState() {
    super.initState();
    // Load cancelled invoice details
    context.read<CancelledInvoiceBloc>().add(
      LoadCancelledInvoicesByIdEvent(widget.cancelledInvoiceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.returnsNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/undeliverable-customers',
      onNavigate: (route) {
        context.go(route);
      },
      onThemeToggle: () {
        // Handle theme toggle
      },
      onNotificationTap: () {
        // Handle notification tap
      },
      onProfileTap: () {
        // Handle profile tap
      },
      disableScrolling: true,
      child: BlocBuilder<CancelledInvoiceBloc, CancelledInvoiceState>(
        builder: (context, state) {
          if (state is CancelledInvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CancelledInvoiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CancelledInvoiceBloc>().add(
                        LoadCancelledInvoicesByIdEvent(
                          widget.cancelledInvoiceId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SpecificCancelledInvoiceLoaded) {
            final cancelledInvoice = state.cancelledInvoice;

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  floating: true,
                  snap: true,
                  title: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          context.go('/cancelled-invoices');
                        },
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Cancelled Invoice Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  actions: [
                    // Breadcrumb
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Text(
                          'Return Data > Cancelled Invoices > ${cancelledInvoice.invoice?.name ?? 'Details'}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Widget
                      CancelledInvoiceHeaderWidget(
                        cancelledInvoice: cancelledInvoice,
                        onViewImagePressed:
                            () => _showImageDialog(
                              context,
                              cancelledInvoice.image,
                            ),
                       
                      ),

                      const SizedBox(height: 24),

                      // Dashboard Widget
                      CancelledInvoiceDashboardWidget(
                        cancelledInvoice: cancelledInvoice,
                      ),

                      const SizedBox(height: 24),

                      // Invoice Items Table
                      if (cancelledInvoice.invoice?.id != null)
                        CancelledInvoiceItemsTable(
                          invoiceId: cancelledInvoice.invoice!.id!,
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Invoice Items Available',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Invoice ID not found for this cancelled invoice.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            );
          }

          // Default state - no data loaded yet
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
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cancelled Invoice Image',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            const Text('Failed to load image'),
                          ],
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
}
