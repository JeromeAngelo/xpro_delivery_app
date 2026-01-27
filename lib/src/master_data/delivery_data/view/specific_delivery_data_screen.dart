import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/specific_delivery_data_screen.dart/specific_delivery_data_dashboard.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/specific_delivery_data_screen.dart/customer_data_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/specific_delivery_data_screen.dart/invoice_delivery_data_table.dart';

import '../widgets/specific_delivery_data_screen.dart/invoice_items_delivery_data_tbl.dart';

class SpecificDeliveryDataScreen extends StatefulWidget {
  final String deliveryId;

  const SpecificDeliveryDataScreen({super.key, required this.deliveryId});

  @override
  State<SpecificDeliveryDataScreen> createState() =>
      _SpecificDeliveryDataScreenState();
}

class _SpecificDeliveryDataScreenState
    extends State<SpecificDeliveryDataScreen> {
  @override
  void initState() {
    super.initState();
    // Load delivery data when screen initializes
    context.read<DeliveryDataBloc>().add(
      GetDeliveryDataByIdEvent(widget.deliveryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/delivery-list',
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
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          if (state is DeliveryDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeliveryDataError) {
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
                      context.read<DeliveryDataBloc>().add(
                        GetDeliveryDataByIdEvent(widget.deliveryId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DeliveryDataLoaded) {
            final deliveryData = state.deliveryData;

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
                          context.go('/delivery-list');
                        },
                      ),
                      Text('Delivery: ${deliveryData.deliveryNumber ?? 'N/A'}'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        context.read<DeliveryDataBloc>().add(
                          GetDeliveryDataByIdEvent(widget.deliveryId),
                        );
                      },
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Delivery Dashboard
                      DeliveryDataDashboardWidget(delivery: deliveryData),

                      const SizedBox(height: 16),

                      // Customer Data Table
                      CustomerDataTableWidget(
                        deliveryData: deliveryData,
                        onCustomerEdit: () {
                          _handleEditCustomer(deliveryData.customer?.id);
                        },
                        onCustomerView: () {
                          _handleViewCustomer(deliveryData.customer?.id);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Invoice Data Table
                      InvoiceDeliveryDataWidget(
                        deliveryData: deliveryData,
                        onInvoiceEdit: () {
                          _handleEditInvoice(deliveryData.invoice?.id);
                        },
                        onInvoiceView: () {
                          _handleViewInvoice(deliveryData.invoice?.id);
                        },
                        onViewItems: () {
                          _handleViewInvoiceItems(deliveryData.invoiceItems);
                        },
                      ),
                      InvoiceItemsDeliveryDataWidget(
                        deliveryData: deliveryData,
                      ),
                      // Add some bottom padding
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Select a delivery to view details'));
        },
      ),
    );
  }

  void _handleEditCustomer(String? customerId) {
    if (customerId != null) {
      // Navigate to edit customer screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit customer feature coming soon'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customer data available to edit'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _handleViewCustomer(String? customerId) {
    if (customerId != null) {
      // Navigate to customer details screen
      context.go('/customer-details/$customerId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customer data available to view'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _handleEditInvoice(String? invoiceId) {
    if (invoiceId != null) {
      // Navigate to edit invoice screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit invoice feature coming soon'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoice data available to edit'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _handleViewInvoice(String? invoiceId) {
    if (invoiceId != null) {
      // Navigate to invoice details screen
      context.go('/invoice/$invoiceId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoice data available to view'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _handleViewInvoiceItems(List<dynamic>? invoiceItems) {
    if (invoiceItems != null && invoiceItems.isNotEmpty) {
      _showInvoiceItemsDialog(context, invoiceItems);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoice items available'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _showInvoiceItemsDialog(
    BuildContext context,
    List<dynamic> invoiceItems,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Invoice Items (${invoiceItems.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child:
                invoiceItems.isEmpty
                    ? const Center(child: Text('No invoice items available'))
                    : ListView.builder(
                      itemCount: invoiceItems.length,
                      itemBuilder: (context, index) {
                        final item = invoiceItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item?.name ?? 'Unnamed Item',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item?.description != null)
                                  Text('Description: ${item.description}'),
                                if (item?.quantity != null)
                                  Text('Quantity: ${item.quantity}'),
                                if (item?.price != null)
                                  Text('Price: ₱${item.price}'),
                                if (item?.quantity != null &&
                                    item?.price != null)
                                  Text(
                                    'Total: ₱${(item.quantity * item.price).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                _showItemDetailsDialog(
                                  context,
                                  item,
                                  index + 1,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export invoice items feature coming soon'),
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDetailsDialog(
    BuildContext context,
    dynamic item,
    int itemNumber,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Item #$itemNumber Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemDetailRow('Item ID', item?.id ?? 'N/A'),
              _buildItemDetailRow('Name', item?.name ?? 'N/A'),
              _buildItemDetailRow('Description', item?.description ?? 'N/A'),
              _buildItemDetailRow('Quantity', '${item?.quantity ?? 'N/A'}'),
              _buildItemDetailRow(
                'Unit Price',
                item?.price != null ? '₱${item.price}' : 'N/A',
              ),
              _buildItemDetailRow(
                'Total Amount',
                item?.quantity != null && item?.price != null
                    ? '₱${(item.quantity * item.price).toStringAsFixed(2)}'
                    : 'N/A',
              ),
              _buildItemDetailRow('Category', item?.category ?? 'N/A'),
              _buildItemDetailRow('SKU', item?.sku ?? 'N/A'),
              _buildItemDetailRow(
                'Weight',
                item?.weight != null ? '${item.weight} kg' : 'N/A',
              ),
              _buildItemDetailRow('Dimensions', item?.dimensions ?? 'N/A'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit item feature coming soon'),
                  ),
                );
              },
              child: const Text('Edit Item'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'N/A' ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
