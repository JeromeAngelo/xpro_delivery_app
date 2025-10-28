import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'vehicle_capacity_info.dart';

class VehicleSelectionDialog extends StatefulWidget {
  final List<DeliveryVehicleModel> availableVehicles;
  final List<DeliveryVehicleModel> selectedVehicles;
  final Function(List<DeliveryVehicleModel>) onVehiclesChanged;
  final Function(DeliveryVehicleModel?) onVehicleSelectedForCapacityCheck;

  const VehicleSelectionDialog({
    super.key,
    required this.availableVehicles,
    required this.selectedVehicles,
    required this.onVehiclesChanged,
    required this.onVehicleSelectedForCapacityCheck,
  });

  @override
  State<VehicleSelectionDialog> createState() => _VehicleSelectionDialogState();
}

class _VehicleSelectionDialogState extends State<VehicleSelectionDialog> {
  String _searchQuery = '';
  DeliveryVehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    // Initialize with first available vehicle if any
    if (widget.availableVehicles.isNotEmpty) {
      _selectedVehicle = widget.availableVehicles.first;
    }
  }

  List<DeliveryVehicleModel> get filteredVehicles {
    if (_searchQuery.isEmpty) {
      return widget.availableVehicles;
    }
    return widget.availableVehicles.where((vehicle) {
      final plateNo = vehicle.plateNo?.toLowerCase() ?? '';
      final make = vehicle.make?.toLowerCase() ?? '';
      final name = vehicle.name?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return plateNo.contains(query) ||
          make.contains(query) ||
          name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            SizedBox(
              width: 500,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search vehicles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Main content - Left: Vehicle List, Right: Capacity Info
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Vehicle List
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Available Vehicles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            child:
                                filteredVehicles.isEmpty
                                    ? Center(
                                      child: Text(
                                        'No vehicles found',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      itemCount: filteredVehicles.length,
                                      itemBuilder: (context, index) {
                                        final vehicle = filteredVehicles[index];
                                        final isSelected =
                                            _selectedVehicle?.id == vehicle.id;

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Card(
                                            color:
                                                isSelected
                                                    ? Colors.blue.shade50
                                                    : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color:
                                                    isSelected
                                                        ? Colors.blue
                                                        : Colors.grey.shade300,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.blue
                                                    .withOpacity(0.1),
                                                child: const Icon(
                                                  Icons.local_shipping,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              title: Text(
                                                vehicle.plateNo ??
                                                    '${vehicle.make} ${vehicle.name}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isSelected
                                                          ? Colors.blue.shade700
                                                          : Colors.black,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Make: ${vehicle.make ?? 'Unknown'}',
                                                  ),
                                                  Text(
                                                    'Model: ${vehicle.name ?? 'Unknown'}',
                                                  ),
                                                  if (vehicle.weightCapacity !=
                                                      null)
                                                    Text(
                                                      'Weight: ${vehicle.weightCapacity} kg',
                                                    ),
                                                  if (vehicle.volumeCapacity !=
                                                      null)
                                                    Text(
                                                      'Volume: ${vehicle.volumeCapacity} m³',
                                                    ),
                                                ],
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  _selectedVehicle = vehicle;
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right side - Vehicle Capacity Info
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Vehicle Capacity Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child:
                                  _selectedVehicle != null
                                      ? MultiBlocProvider(
                                        providers: [
                                          BlocProvider.value(
                                            value: BlocProvider.of<
                                              DeliveryVehicleBloc
                                            >(context),
                                          ),
                                          BlocProvider.value(
                                            value: BlocProvider.of<
                                              DeliveryDataBloc
                                            >(context),
                                          ),
                                        ],
                                        child: VehicleCapacityInfo(
                                          vehicle: _selectedVehicle,
                                        ),
                                      )
                                      : const Center(
                                        child: Text(
                                          'Select a vehicle to view capacity information',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _selectedVehicle != null
                          ? () {
                            // Add the selected vehicle to the list
                            final updatedList = List<DeliveryVehicleModel>.from(
                              widget.selectedVehicles,
                            );
                            if (!updatedList.contains(_selectedVehicle)) {
                              updatedList.add(_selectedVehicle!);
                            }
                            widget.onVehiclesChanged(updatedList);
                            widget.onVehicleSelectedForCapacityCheck(
                              _selectedVehicle,
                            );
                            Navigator.of(context).pop();
                          }
                          : null,
                  child: const Text('Select Vehicle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
