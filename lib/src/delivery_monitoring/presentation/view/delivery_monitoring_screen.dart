import 'dart:async';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/default_drawer.dart';
import 'package:xpro_delivery_admin_app/src/delivery_monitoring/presentation/widgets/customer_information_tile.dart';
import 'package:xpro_delivery_admin_app/src/delivery_monitoring/presentation/widgets/delivery_status_icon.dart';
import 'package:xpro_delivery_admin_app/src/delivery_monitoring/presentation/widgets/status_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryMonitoringScreen extends StatefulWidget {
  const DeliveryMonitoringScreen({super.key});

  @override
  State<DeliveryMonitoringScreen> createState() =>
      _DeliveryMonitoringScreenState();
}

class _DeliveryMonitoringScreenState extends State<DeliveryMonitoringScreen> {
  final List<DeliveryStatusData> statuses = getAllDeliveryStatuses();

  Timer? _autoRefreshTimer;

  // Auto-refresh duration - 2 minutes
  static const Duration autoRefreshDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    // Load all delivery data when the screen initializes
    context.read<DeliveryDataBloc>().add(
      const GetAllDeliveryDataWithTripsEvent(),
    );

    // Set up auto-refresh timer
    _setupAutoRefreshTimer();
  }

  @override
  void dispose() {
    // Cancel the timer when disposing the widget
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // Set up the auto-refresh timer
  void _setupAutoRefreshTimer() {
    // Cancel any existing timer
    _autoRefreshTimer?.cancel();

    // Create a new timer that fires every 2 minutes
    _autoRefreshTimer = Timer.periodic(
      autoRefreshDuration,
      (_) => _refreshData(),
    );
  }

  // Refresh the data
  void _refreshData() {
    if (mounted) {
      // Show a snackbar to indicate refresh is happening
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-refreshing delivery data...'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh delivery data
      context.read<DeliveryDataBloc>().add(
        const GetAllDeliveryDataWithTripsEvent(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
        title: Text(
          'Delivery Monitoring',
          style: TextStyle(color: Theme.of(context).colorScheme.surface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (count) =>
                      autoRefreshDuration.inSeconds -
                      (count % autoRefreshDuration.inSeconds),
                ),
                builder: (context, snapshot) {
                  final remainingSeconds =
                      snapshot.data ?? autoRefreshDuration.inSeconds;
                  final minutes = remainingSeconds ~/ 60;
                  final seconds = remainingSeconds % 60;
                  return Text(
                    'Auto-refresh in: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.sort_outlined,
              color: Theme.of(context).colorScheme.surface,
            ),
            tooltip: 'Filter',
            onPressed: () {
              // Filter functionality can be added here if needed
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.surface,
            ),
            tooltip: 'Refresh',
            onPressed: () {
              // Manually refresh delivery data
              context.read<DeliveryDataBloc>().add(
                const GetAllDeliveryDataWithTripsEvent(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const DefaultDrawer(),
      body: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          if (state is DeliveryDataLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeliveryDataError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading delivery data: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Retry loading delivery data
                      context.read<DeliveryDataBloc>().add(
                        const GetAllDeliveryDataWithTripsEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          List<DeliveryDataEntity> deliveryDataList = [];

          // Handle different loaded states
          if (state is AllDeliveryDataWithTripsLoaded) {
            deliveryDataList = state.deliveryData;
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columns
                    childAspectRatio: 0.85, // Adjust for height
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final status = statuses[index];
                    final statusDeliveryData = _filterDeliveryDataByStatus(
                      deliveryDataList,
                      status.name,
                    );

                    return SizedBox(
                      height: 500, // Fixed height for each status container
                      child: StatusContainer(
                        statusName: status.name,
                        statusIcon: status.icon,
                        statusColor: status.color,
                        deliveryDataList: statusDeliveryData,
                        onDeliveryDataTap: (deliveryData) {
                          _showDeliveryDataDetails(context, deliveryData);
                        },
                        subtitle: status.subtitle,
                      ),
                    );
                  }, childCount: statuses.length),
                ),
              ),
            ],
          );
        },
      ),
      // Add a floating action button to manually refresh
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Manually refresh delivery data
          context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataEvent());
        },
        tooltip: 'Refresh delivery data',
        child: const Icon(Icons.sync),
      ),
    );
  }

  // Filter delivery data by their delivery status
  List<DeliveryDataEntity> _filterDeliveryDataByStatus(
    List<DeliveryDataEntity> deliveryDataList,
    String status,
  ) {
    final statusLower = status.toLowerCase();

    return deliveryDataList.where((deliveryData) {
      // Get the most recent delivery status
      final deliveryStatus =
          deliveryData.deliveryUpdates.isNotEmpty
              ? deliveryData.deliveryUpdates.last.title?.toLowerCase() ?? ''
              : '';

      // Match status names (simplified)
      if (statusLower == 'pending' && deliveryStatus.isEmpty) {
        return true;
      }

      if (deliveryStatus.contains(statusLower)) {
        return true;
      }

      if (statusLower == 'waiting for customer' &&
          (deliveryStatus.contains('waiting for customer'))) {
        return true;
      }

      // Special cases
      if (statusLower == 'delivered' &&
          (deliveryStatus.contains('mark as received'))) {
        return true;
      }

      if (statusLower == 'mark as undelivered' &&
          deliveryStatus.contains('mark as undelivered')) {
        return true;
      }

      if (statusLower == 'completed' &&
          deliveryStatus.contains('end delivery')) {
        return true;
      }

      return false;
    }).toList();
  }

  // Show delivery data details in a dialog
  void _showDeliveryDataDetails(
    BuildContext context,
    DeliveryDataEntity deliveryData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Details',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ],
                    ),
                  ),

                  // Delivery data information content
                  Flexible(
                    child: SingleChildScrollView(
                      child: CustomerInformationTile(
                        deliveryData: deliveryData,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
