import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/presentation/bloc/vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/presentation/bloc/vehicle_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/vehicle_management/widgets/vehicle_screen_widgets/vehicle_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class VehicleDataTable extends StatelessWidget {
  final List<DeliveryVehicleEntity> vehicles;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const VehicleDataTable({
    super.key,
    required this.vehicles,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Vehicles',
      searchBar: VehicleSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create vehicle screen
        _showCreateVehicleDialog(context);
      },
      createButtonText: 'Add Vehicle',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Plate Number')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Volume Capacity')),
        DataColumn(label: Text('Weight Capacity')),

        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          vehicles.map((vehicle) {
            return DataRow(
              cells: [
                DataCell(Text(vehicle.id ?? 'N/A')),
                DataCell(Text(vehicle.make ?? 'N/A')),
                DataCell(Text(vehicle.name ?? 'N/A')),
                DataCell(Text(vehicle.type ?? 'N/A')),
                DataCell(Text('${vehicle.volumeCapacity ?? 'N/A'} cm3')),
                DataCell(Text('${vehicle.weightCapacity ?? 'N/A'} cm3')),

                DataCell(Text(_formatDate(vehicle.created))),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View vehicle details
                          if (vehicle.id != null) {
                            // Navigate to vehicle details screen
                            context.go('/vehicle/${vehicle.id}');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit vehicle
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // Show confirmation dialog before deleting
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,
      onFiltered: () {
        // Show filter options
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter options coming soon')),
        );
      },
      dataLength: '${vehicles.length}',
      onDeleted: () {},
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _showCreateVehicleDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final plateNumberController = TextEditingController();
    final typeController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Vehicle'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Name',
                    hintText: 'Enter vehicle name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: plateNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    hintText: 'Enter plate number',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    hintText: 'Enter vehicle type',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    plateNumberController.text.isNotEmpty &&
                    typeController.text.isNotEmpty) {
                  context.read<VehicleBloc>().add(
                    CreateVehicleEvent(
                      vehicleName: nameController.text,
                      vehiclePlateNumber: plateNumberController.text,
                      vehicleType: typeController.text,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
      plateNumberController.dispose();
      typeController.dispose();
    });
  }

  
}
