import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/customer_details_dashboard.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/maps.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/delivery_timeline.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_delivery_btn.dart';

// CLEANED DeliveryMainScreen — No Cached State, No Redundant Fetching,
// FULL OFFLINE MODE (ObjectBox as single source of truth)

class DeliveryMainScreen extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const DeliveryMainScreen({super.key, this.selectedCustomer});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen>
    with AutomaticKeepAliveClientMixin {
  bool isMapMinimized = false;

  late final DeliveryDataBloc _deliveryDataBloc;
  late final DeliveryUpdateBloc _deliveryUpdateBloc;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();

    if (widget.selectedCustomer != null) {
      debugPrint('📦 Initial delivery data: ${widget.selectedCustomer!.id}');
    }

    _loadInitialLocalData(); // Load only ONCE
  }

  void _initializeBlocs() {
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
  }

  // Load from local DB ONCE
  void _loadInitialLocalData() {
    final id = widget.selectedCustomer?.id;
    if (id == null) return;

    _deliveryDataBloc.add(GetDeliveryDataByIdEvent(id));
    _deliveryUpdateBloc.add(GetDeliveryStatusChoicesEvent(id));
  }

  // Manual pull to refresh
  Future<void> _refreshData() async {
    final id = widget.selectedCustomer?.id;
    if (id == null) return;

    debugPrint('🔄 MANUAL REFRESH — local data only');

    _deliveryDataBloc.add(GetDeliveryDataByIdEvent(id));
    _deliveryUpdateBloc.add(GetDeliveryStatusChoicesEvent(id));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
      builder: (context, state) {
        debugPrint('📱 Building DeliveryMainScreen with state: ${state.runtimeType}');

        // 🧩 Use navigation data as fallback
        DeliveryDataEntity? deliveryData = widget.selectedCustomer;

        if (state is DeliveryDataLoaded) {
          deliveryData = state.deliveryData;
        }

        if (deliveryData == null) {
          return const Scaffold(
            body: Center(child: Text('No delivery data available')),
          );
        }

        return _buildSelectedCustomerView(deliveryData);
      },
    );
  }

  Widget _buildSelectedCustomerView(DeliveryDataEntity deliveryData) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  CustomerDetailsDashboard(
                    deliveryData: deliveryData,
                    onTap: () {},
                  ),

                  _buildMapSection(deliveryData),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 16.0),
                      child: Text(
                        'Delivery Timeline',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  DeliveryTimeline(customerId: '${deliveryData.id}'),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: UpdateDeliveryBtn(
        currentStatus: _getCurrentDeliveryStatus(deliveryData),
        customerId: deliveryData.id ?? '',
      ),
    );
  }

  String _getCurrentDeliveryStatus(DeliveryDataEntity deliveryData) {
    final updates = deliveryData.deliveryUpdates.toList();
    return updates.isNotEmpty ? updates.last.title ?? '' : '';
  }

  Widget _buildMapSection(DeliveryDataEntity deliveryData) {
    final latestStatus = _getCurrentDeliveryStatus(deliveryData).toLowerCase();
    final hide = ['arrived', 'unloading', 'mark as received', 'end delivery'];

    if (hide.contains(latestStatus)) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: CustomerMapScreen(
        selectedCustomer: deliveryData,
        height: isMapMinimized ? 150 : 300,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}