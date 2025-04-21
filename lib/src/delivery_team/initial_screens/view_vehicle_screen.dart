import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/domain/entity/vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

class ViewVehicleScreen extends StatefulWidget {
  const ViewVehicleScreen({super.key});

  @override
  State<ViewVehicleScreen> createState() => _ViewVehicleScreenState();
}

class _ViewVehicleScreenState extends State<ViewVehicleScreen> {
  VehicleState? _cachedState;
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  void _loadVehicleData() {
    if (!_isDataInitialized) {
      final tripState = context.read<TripBloc>().state;
      if (tripState is TripLoaded && tripState.trip.id != null) {
        debugPrint(
            '📱 Loading local vehicle data for trip: ${tripState.trip.id}');
        context.read<VehicleBloc>()
          ..add(LoadLocalVehicleByTripIdEvent(tripState.trip.id!))
          ..add(LoadVehicleByTripIdEvent(tripState.trip.id!));
        _isDataInitialized = true;
      }
    }
  }

  Future<void> _refreshData() async {
    final tripState = context.read<TripBloc>().state;
    if (tripState is TripLoaded && tripState.trip.id != null) {
      context.read<VehicleBloc>().add(
            LoadVehicleByTripIdEvent(tripState.trip.id!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocBuilder<VehicleBloc, VehicleState>(
          buildWhen: (previous, current) =>
              current is VehicleByTripLoaded || _cachedState == null,
          builder: (context, state) {
            if (state is VehicleByTripLoaded) {
              _cachedState = state;
              return _buildVehicleDetails(state.vehicle);
            }

            final cachedState = _cachedState;
            if (cachedState is VehicleByTripLoaded) {
              return _buildVehicleDetails(cachedState.vehicle);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(VehicleEntity vehicle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VehicleHeaderCard(vehicle: vehicle),
          const SizedBox(height: 20),
          _VehicleDetailsCard(vehicle: vehicle),
          const SizedBox(height: 20),
          _VehicleTimelineCard(vehicle: vehicle),
        ],
      ),
    );
  }
}

class _VehicleHeaderCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const _VehicleHeaderCard({required this.vehicle});

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
              vehicle.vehicleName ?? 'Unnamed Vehicle',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              vehicle.vehiclePlateNumber ?? 'No Plate Number',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleDetailsCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const _VehicleDetailsCard({required this.vehicle});

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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Type',
              vehicle.vehicleType ?? 'Not Specified',
              Icons.category,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Trip Number',
              vehicle.trip.target?.tripNumberId ?? 'Not Assigned',
              Icons.confirmation_number,
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
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTimelineCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const _VehicleTimelineCard({required this.vehicle});

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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
