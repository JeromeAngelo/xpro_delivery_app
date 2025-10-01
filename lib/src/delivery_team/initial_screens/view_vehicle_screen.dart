import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/empty_screen_message.dart';

class ViewVehicleScreen extends StatefulWidget {
  final DeliveryTeamEntity? deliveryTeam;

  const ViewVehicleScreen({super.key, this.deliveryTeam});

  @override
  State<ViewVehicleScreen> createState() => _ViewVehicleScreenState();
}

class _ViewVehicleScreenState extends State<ViewVehicleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Vehicle Details'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildVehicleContent(),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Refresh logic can be added here if needed
    setState(() {});
  }

  Widget _buildVehicleContent() {
    // Check if delivery team data is available
    if (widget.deliveryTeam == null) {
      return const EmptyScreenMessage(
        message: "No Delivery Team Data Available",
      );
    }

    // Get delivery vehicle from delivery team
    final deliveryVehicle = widget.deliveryTeam!.deliveryVehicle.target;

    if (deliveryVehicle == null) {
      return const EmptyScreenMessage(message: "No Delivery Vehicle Assigned");
    }

    return _buildDeliveryVehicleDetails(deliveryVehicle);
  }

  Widget _buildDeliveryVehicleDetails(DeliveryVehicleEntity vehicle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeliveryVehicleHeaderCard(vehicle: vehicle),
          const SizedBox(height: 20),
          _DeliveryVehicleDetailsCard(vehicle: vehicle),
          const SizedBox(height: 20),
          _DeliveryVehicleSpecsCard(vehicle: vehicle),
          const SizedBox(height: 20),
          _DeliveryVehicleTimelineCard(vehicle: vehicle),
        ],
      ),
    );
  }
}

class _DeliveryVehicleHeaderCard extends StatelessWidget {
  final DeliveryVehicleEntity vehicle;

  const _DeliveryVehicleHeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.local_shipping,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              vehicle.name ?? 'Unnamed Vehicle',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              vehicle.plateNo ?? 'No Plate Number',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryVehicleDetailsCard extends StatelessWidget {
  final DeliveryVehicleEntity vehicle;

  const _DeliveryVehicleDetailsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Make',
              vehicle.make ?? 'Not Specified',
              Icons.business,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Type',
              vehicle.type ?? 'Not Specified',
              Icons.category,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Wheels',
              vehicle.wheels ?? 'Not Specified',
              Icons.tire_repair,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryVehicleSpecsCard extends StatelessWidget {
  final DeliveryVehicleEntity vehicle;

  const _DeliveryVehicleSpecsCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Specifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSpecRow(
              context,
              'Volume Capacity',
              vehicle.volumeCapacity != null
                  ? '${vehicle.volumeCapacity} m³'
                  : 'Not Specified',
              Icons.inventory,
            ),
            const Divider(),
            _buildSpecRow(
              context,
              'Weight Capacity',
              vehicle.weightCapacity != null
                  ? '${vehicle.weightCapacity} kg'
                  : 'Not Specified',
              Icons.scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryVehicleTimelineCard extends StatelessWidget {
  final DeliveryVehicleEntity vehicle;

  const _DeliveryVehicleTimelineCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              context,
              'Created',
              vehicle.created,
              Icons.add_circle,
            ),
            if (vehicle.updated != null)
              _buildTimelineItem(
                context,
                'Last Updated',
                vehicle.updated,
                Icons.update,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    DateTime? date,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  _formatDate(date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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

// // ADDED: Loading state widget for when delivery team data is being fetched
// class _LoadingVehicleWidget extends StatelessWidget {
//   const _LoadingVehicleWidget();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 16),
//           Text('Loading vehicle information...'),
//         ],
//       ),
//     );
//   }
// }

// // ADDED: Error state widget for when there's an error loading data
// class _ErrorVehicleWidget extends StatelessWidget {
//   final String message;
//   final VoidCallback? onRetry;

//   const _ErrorVehicleWidget({
//     required this.message,
//     this.onRetry,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 64,
//             color: Theme.of(context).colorScheme.error,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Error Loading Vehicle Data',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: Theme.of(context).textTheme.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//           if (onRetry != null) ...[
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: onRetry,
//               child: const Text('Retry'),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ADDED: Status badge widget for vehicle status
// class _VehicleStatusBadge extends StatelessWidget {
//   final String? status;

//   const _VehicleStatusBadge({this.status});

//   @override
//   Widget build(BuildContext context) {
//     final statusText = status ?? 'Unknown';
//     Color badgeColor;
//     IconData statusIcon;

//     switch (statusText.toLowerCase()) {
//       case 'active':
//       case 'available':
//         badgeColor = Colors.green;
//         statusIcon = Icons.check_circle;
//         break;
//       case 'in_use':
//       case 'busy':
//         badgeColor = Colors.orange;
//         statusIcon = Icons.local_shipping;
//         break;
//       case 'maintenance':
//         badgeColor = Colors.red;
//         statusIcon = Icons.build;
//         break;
//       case 'inactive':
//         badgeColor = Colors.grey;
//         statusIcon = Icons.pause_circle;
//         break;
//       default:
//         badgeColor = Colors.blue;
//         statusIcon = Icons.help;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: badgeColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: badgeColor),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(statusIcon, size: 16, color: badgeColor),
//           const SizedBox(width: 4),
//           Text(
//             statusText.toUpperCase(),
//             style: TextStyle(
//               color: badgeColor,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
