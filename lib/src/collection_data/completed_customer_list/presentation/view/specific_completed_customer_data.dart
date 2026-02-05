import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/domain/entity/collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';

import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/completed_customer_list/presentation/widgets/specific_customer_data_widgets/completed_customer_dashboard_widget.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/completed_customer_list/presentation/widgets/specific_customer_data_widgets/completed_customer_invoice_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SpecificCompletedCustomerData extends StatefulWidget {
  final String collectionId;

  const SpecificCompletedCustomerData({super.key, required this.collectionId});

  @override
  State<SpecificCompletedCustomerData> createState() =>
      _SpecificCompletedCustomerDataState();
}

class _SpecificCompletedCustomerDataState
    extends State<SpecificCompletedCustomerData> {
  int _currentPage = 1;
  final int _totalPages = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();

    // Extract the actual ID if needed
    String collectionId = widget.collectionId;
    if (collectionId.contains('CollectionEntity')) {
      // Extract just the ID
      final idMatch = RegExp(
        r'CollectionEntity\(([^,]+)',
      ).firstMatch(collectionId);
      if (idMatch != null && idMatch.groupCount >= 1) {
        collectionId = idMatch.group(1)!;
      } else {
        // Fallback
        collectionId =
            collectionId
                .split(',')
                .first
                .replaceAll('CollectionEntity(', '')
                .trim();
      }
    }

    debugPrint('🔍 Loading collection details for ID: $collectionId');

    // Load collection details
    context.read<CollectionsBloc>().add(GetCollectionByIdEvent(collectionId));
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.collectionNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/completed-customers',
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
      child: BlocBuilder<CollectionsBloc, CollectionsState>(
        builder: (context, state) {
          debugPrint('🔄 Current collections state: ${state.runtimeType}');

          if (state is CollectionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CollectionsError) {
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
                      context.read<CollectionsBloc>().add(
                        GetCollectionByIdEvent(widget.collectionId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CollectionLoaded) {
            final collection = state.collection;

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
                          context.go('/completed-collections');
                        },
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        context.read<CollectionsBloc>().add(
                          GetCollectionByIdEvent(widget.collectionId),
                        );
                        if (collection.customer?.id != null) {
                          context.read<InvoiceDataBloc>().add(
                            GetInvoiceDataByCustomerIdEvent(
                              collection.customer!.id!,
                            ),
                          );
                        }
                      },
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.print),
                    //   tooltip: 'Print Collection Receipt',
                    //   onPressed: () {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(
                    //         content: Text(
                    //           'Printing receipt for ${collection.collectionName ?? 'collection'}...',
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // IconButton(
                    //   icon: const Icon(Icons.picture_as_pdf),
                    //   tooltip: 'Export PDF',
                    //   onPressed: () {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(
                    //         content: Text(
                    //           'Exporting PDF for ${collection.collectionName ?? 'collection'}...',
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Collection Dashboard
                      CompletedCustomerDashboardWidget(collection: collection),

                      const SizedBox(height: 16),

                      // // Customer Information Card
                      // if (collection.customer != null)
                      //   Card(
                      //     margin: const EdgeInsets.only(bottom: 16),
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(16.0),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'Customer Information',
                      //             style: Theme.of(context).textTheme.titleLarge
                      //                 ?.copyWith(fontWeight: FontWeight.bold),
                      //           ),
                      //           const SizedBox(height: 16),
                      //           Row(
                      //             children: [
                      //               Expanded(
                      //                 child: ListTile(
                      //                   leading: const Icon(
                      //                     Icons.store,
                      //                     color: Colors.blue,
                      //                   ),
                      //                   title: Text(
                      //                     'Store: ${collection.customer?.name ?? 'N/A'}',
                      //                   ),
                      //                   subtitle: Text(
                      //                     'Owner: ${collection.customer?.ownerName ?? 'N/A'}',
                      //                   ),
                      //                 ),
                      //               ),
                      //               Expanded(
                      //                 child: ListTile(
                      //                   leading: const Icon(
                      //                     Icons.phone,
                      //                     color: Colors.green,
                      //                   ),
                      //                   title: Text(
                      //                     'Contact: ${collection.customer?.contactNumber ?? 'N/A'}',
                      //                   ),
                      //                   subtitle: Text(
                      //                     'Address: ${collection.customer?.province ?? 'N/A'}',
                      //                   ),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),

                      // // Trip Information Card
                      // if (collection.trip != null)
                      //   Card(
                      //     margin: const EdgeInsets.only(bottom: 16),
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(16.0),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'Trip Information',
                      //             style: Theme.of(context).textTheme.titleLarge
                      //                 ?.copyWith(fontWeight: FontWeight.bold),
                      //           ),
                      //           const SizedBox(height: 16),
                      //           ListTile(
                      //             leading: const Icon(
                      //               Icons.local_shipping,
                      //               color: Colors.orange,
                      //             ),
                      //             title: Text(
                      //               'Trip Number: ${collection.trip?.tripNumberId ?? 'N/A'}',
                      //             ),
                      //             subtitle: Text(
                      //               'Status: ${collection.trip?.isEndTrip == true ? 'Completed' : 'Active'}',
                      //             ),
                      //             trailing: ElevatedButton(
                      //               onPressed: () {
                      //                 if (collection.trip?.id != null) {
                      //                   context.go(
                      //                     '/collections/${collection.trip!.id}',
                      //                   );
                      //                 }
                      //               },
                      //               child: const Text('View Trip'),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),

                      // Related Collections Table (if needed)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Collection Invoice Table
                              BlocBuilder<CollectionsBloc, CollectionsState>(
                                builder: (context, collectionState) {
                                  List<CollectionEntity> collections = [];
                                  bool isLoadingCollections = false;
                                  String? collectionError;

                                  if (collectionState is CollectionsLoading) {
                                    isLoadingCollections = true;
                                  } else if (collectionState
                                      is CollectionLoaded) {
                                    // Use the current collection from the state
                                    collections = [collectionState.collection];
                                  } else if (collectionState
                                      is CollectionsLoaded) {
                                    // If multiple collections are loaded, use them
                                    collections = collectionState.collections;
                                  } else if (collectionState
                                      is CollectionsError) {
                                    collectionError = collectionState.message;
                                  }

                                  return CompletedCustomerInvoiceTable(
                                    collections: collections,
                                    isLoading: isLoadingCollections,
                                    currentPage: _currentPage,
                                    totalPages: _totalPages,
                                    onPageChanged: (page) {
                                      setState(() {
                                        _currentPage = page;
                                      });
                                    },
                                    completedCustomerId: collection.id,
                                    errorMessage: collectionError,
                                    onRetry: () {
                                      // Retry loading the collection
                                      context.read<CollectionsBloc>().add(
                                        GetCollectionByIdEvent(
                                          widget.collectionId,
                                        ),
                                      );

                                      // Also retry loading invoices if customer ID exists
                                      if (collection.customer?.id != null) {
                                        context.read<InvoiceDataBloc>().add(
                                          GetInvoiceDataByCustomerIdEvent(
                                            collection.customer!.id!,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // // Delivery Information Card
                      // if (collection.deliveryData != null)
                      //   Card(
                      //     margin: const EdgeInsets.only(bottom: 16),
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(16.0),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'Delivery Information',
                      //             style: Theme.of(context).textTheme.titleLarge
                      //                 ?.copyWith(fontWeight: FontWeight.bold),
                      //           ),
                      //           const SizedBox(height: 16),
                      //           Row(
                      //             children: [
                      //               Expanded(
                      //                 child: ListTile(
                      //                   leading: const Icon(
                      //                     Icons.local_shipping,
                      //                     color: Colors.indigo,
                      //                   ),
                      //                   title: Text(
                      //                     'Delivery #: ${collection.deliveryData?.deliveryNumber ?? 'N/A'}',
                      //                   ),
                      //                   subtitle: Text(
                      //                     'Status: ${collection.deliveryData?.status ?? 'N/A'}',
                      //                   ),
                      //                 ),
                      //               ),
                      //               Expanded(
                      //                 child: ListTile(
                      //                   leading: const Icon(
                      //                     Icons.access_time,
                      //                     color: Colors.amber,
                      //                   ),
                      //                   title: Text(
                      //                     'Delivered At: ${collection.deliveryData?.deliveredAt != null ? collection.deliveryData!.deliveredAt.toString() : 'N/A'}',
                      //                   ),
                      //                   subtitle: Text(
                      //                     'Driver: ${collection.deliveryData?.driverName ?? 'N/A'}',
                      //                   ),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),

                      // Action Buttons Card
                      // Card(
                      //   margin: const EdgeInsets.only(bottom: 16),
                      //   child: Padding(
                      //     padding: const EdgeInsets.all(16.0),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           'Actions',
                      //           style: Theme.of(context).textTheme.titleLarge
                      //               ?.copyWith(fontWeight: FontWeight.bold),
                      //         ),
                      //         const SizedBox(height: 16),
                      //         Wrap(
                      //           spacing: 8,
                      //           runSpacing: 8,
                      //           children: [
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 ScaffoldMessenger.of(
                      //                   context,
                      //                 ).showSnackBar(
                      //                   SnackBar(
                      //                     content: Text(
                      //                       'Printing receipt for ${collection.collectionName ?? 'collection'}...',
                      //                     ),
                      //                   ),
                      //                 );
                      //               },
                      //               icon: const Icon(Icons.print),
                      //               label: const Text('Print Receipt'),
                      //               style: ElevatedButton.styleFrom(
                      //                 backgroundColor: Colors.blue,
                      //                 foregroundColor: Colors.white,
                      //               ),
                      //             ),
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 ScaffoldMessenger.of(
                      //                   context,
                      //                 ).showSnackBar(
                      //                   SnackBar(
                      //                     content: Text(
                      //                       'Exporting PDF for ${collection.collectionName ?? 'collection'}...',
                      //                     ),
                      //                   ),
                      //                 );
                      //               },
                      //               icon: const Icon(Icons.picture_as_pdf),
                      //               label: const Text('Export PDF'),
                      //               style: ElevatedButton.styleFrom(
                      //                 backgroundColor: Colors.red,
                      //                 foregroundColor: Colors.white,
                      //               ),
                      //             ),
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 ScaffoldMessenger.of(
                      //                   context,
                      //                 ).showSnackBar(
                      //                   SnackBar(
                      //                     content: Text(
                      //                       'Sending email for ${collection.collectionName ?? 'collection'}...',
                      //                     ),
                      //                   ),
                      //                 );
                      //               },
                      //               icon: const Icon(Icons.email),
                      //               label: const Text('Send Email'),
                      //               style: ElevatedButton.styleFrom(
                      //                 backgroundColor: Colors.green,
                      //                 foregroundColor: Colors.white,
                      //               ),
                      //             ),
                      //             if (collection.invoice != null)
                      //               ElevatedButton.icon(
                      //                 onPressed: () {
                      //                   if (collection.invoice?.id != null) {
                      //                     context.go(
                      //                       '/invoice/${collection.invoice!.id}',
                      //                     );
                      //                   }
                      //                 },
                      //                 icon: const Icon(Icons.receipt_long),
                      //                 label: const Text('View Invoice'),
                      //                 style: ElevatedButton.styleFrom(
                      //                   backgroundColor: Colors.purple,
                      //                   foregroundColor: Colors.white,
                      //                 ),
                      //               ),
                      //             if (collection.trip != null)
                      //               ElevatedButton.icon(
                      //                 onPressed: () {
                      //                   if (collection.trip?.id != null) {
                      //                     context.go(
                      //                       '/trips/${collection.trip!.id}',
                      //                     );
                      //                   }
                      //                 },
                      //                 icon: const Icon(Icons.local_shipping),
                      //                 label: const Text('View Trip'),
                      //                 style: ElevatedButton.styleFrom(
                      //                   backgroundColor: Colors.orange,
                      //                   foregroundColor: Colors.white,
                      //                 ),
                      //               ),
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 context.read<CollectionsBloc>().add(
                      //                   GetCollectionByIdEvent(
                      //                     widget.collectionId,
                      //                   ),
                      //                 );
                      //                 if (collection.customer?.id != null) {
                      //                   context.read<InvoiceDataBloc>().add(
                      //                     GetInvoiceDataByCustomerIdEvent(
                      //                       collection.customer!.id!,
                      //                     ),
                      //                   );
                      //                 }
                      //               },
                      //               icon: const Icon(Icons.refresh),
                      //               label: const Text('Refresh Data'),
                      //               style: ElevatedButton.styleFrom(
                      //                 backgroundColor: Colors.grey,
                      //                 foregroundColor: Colors.white,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),

                      // const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          }

          // Default state - show loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
