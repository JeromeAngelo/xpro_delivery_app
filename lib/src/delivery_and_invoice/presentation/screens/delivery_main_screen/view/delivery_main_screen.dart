import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/customer_details_dashboard.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/maps.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/delivery_timeline.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_delivery_btn.dart';

class DeliveryMainScreen extends StatefulWidget {
  final CustomerEntity? selectedCustomer;

  const DeliveryMainScreen({
    super.key,
    this.selectedCustomer,
  });

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen>
    with AutomaticKeepAliveClientMixin {
  bool isMapMinimized = false;
  bool _isDataInitialized = false;
  CustomerState? _cachedState;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCustomer != null) {
      _cachedState = CustomerLocationLoaded(widget.selectedCustomer!);
    }
    _initializeLocalData();
  }

  void _initializeLocalData() {
    if (!_isDataInitialized && widget.selectedCustomer != null) {
      debugPrint(
          '📱 Loading local data for customer: ${widget.selectedCustomer!.id}');
      context.read<CustomerBloc>().add(
          LoadLocalCustomerLocationEvent(widget.selectedCustomer!.id ?? ''));
      _isDataInitialized = true;
    }
  }

  Future<void> _refreshData() async {
    if (widget.selectedCustomer?.id != null) {
      context
          .read<CustomerBloc>()
          .add(LoadLocalCustomerLocationEvent(widget.selectedCustomer!.id!));
      context.read<DeliveryUpdateBloc>().add(
          LoadLocalDeliveryStatusChoicesEvent(widget.selectedCustomer!.id!));
    }
  }

  double? parseCoordinate(String? value) {
    if (value == null) return null;
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<CustomerBloc, CustomerState>(
      buildWhen: (previous, current) =>
          current is CustomerLocationLoaded || _cachedState == null,
      builder: (context, state) {
        final customerState = _cachedState ?? state;
        if (customerState is CustomerLocationLoaded) {
          return _buildSelectedCustomerView(customerState.customer);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSelectedCustomerView(CustomerEntity customer) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      CustomerDetailsDashboard(
                        customer: customer,
                        onTap: () {
                          final lat = parseCoordinate(customer.latitude);
                          final lng = parseCoordinate(customer.longitude);
                          if (lat != null && lng != null) {
                            // Map focus handling if needed
                          }
                        },
                      ),
                      // Notes section
                      if (customer.hasNotes == true) ...[
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                customer.notes ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                      _buildMapSection(customer),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16.0, top: 16.0, bottom: 8.0),
                          child: Text(
                            'Delivery Timeline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DeliveryTimeline(
                        customerId: customer.id ?? '',
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: UpdateDeliveryBtn(
                currentStatus: customer.deliveryStatus.firstOrNull?.title ?? '',
                customerId: customer.id ?? '',
                isDisabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(CustomerEntity? customer) {
    final latestStatus =
        customer?.deliveryStatus.lastOrNull?.title?.toLowerCase().trim() ?? '';
    debugPrint('🗺️ Latest delivery status: $latestStatus');

    final hideMapStatuses = [
      'arrived',
      'unloading',
      'mark as received',
      'end delivery'
    ];
    final shouldHideMap = hideMapStatuses.contains(latestStatus);

    if (shouldHideMap) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Container(
          height: isMapMinimized ? 150.0 : 300.0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: CustomerMapScreen(
            selectedCustomer: customer,
            height: isMapMinimized ? 150.0 : 300.0,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isMapMinimized ? Icons.expand : Icons.minimize,
                color: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  isMapMinimized = !isMapMinimized;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
