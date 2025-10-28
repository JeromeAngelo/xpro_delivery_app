import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/app_textfield.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_title.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/vehicle_capacity_info.dart';
import 'vehicle_selection_dialog.dart';

class VehicleForm extends StatefulWidget {
  final List<DeliveryVehicleModel> availableVehicles;
  final List<DeliveryVehicleModel> selectedVehicles;
  final Function(List<DeliveryVehicleModel>) onVehiclesChanged;

  const VehicleForm({
    super.key,
    required this.availableVehicles,
    required this.selectedVehicles,
    required this.onVehiclesChanged,
  });

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  DeliveryVehicleModel? _selectedVehicleForCapacityCheck;

  void _showVehicleSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => VehicleSelectionDialog(
            availableVehicles: widget.availableVehicles,
            selectedVehicles: widget.selectedVehicles,
            onVehiclesChanged: widget.onVehiclesChanged,
            onVehicleSelectedForCapacityCheck: (vehicle) {
              setState(() {
                _selectedVehicleForCapacityCheck = vehicle;
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionTitle(title: 'Assign Vehicle'),

        // Main content row - dropdown on left, capacity info on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Vehicle dropdown
            Expanded(flex: 1, child: _buildVehiclesDropdown(context)),

            // Right side - Capacity info (always shown, with or without selected vehicle)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(
                      value: BlocProvider.of<DeliveryVehicleBloc>(context),
                    ),
                    BlocProvider.value(
                      value: BlocProvider.of<DeliveryDataBloc>(context),
                    ),
                  ],
                  child: VehicleCapacityInfo(
                    vehicle: _selectedVehicleForCapacityCheck,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehiclesDropdown(BuildContext context) {
    if (widget.availableVehicles.isEmpty) {
      return const AppTextField(
        label: 'Vehicles',
        initialValue: 'No Vehicles',
        readOnly: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle selection button
        SizedBox(
          width: 755,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle label
              SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Vehicles',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),

              // Custom dropdown button that shows dialog
              Expanded(
                child: InkWell(
                  onTap: _showVehicleSelectionDialog,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.selectedVehicles.isEmpty
                              ? 'Select Vehicle'
                              : '${widget.selectedVehicles.length} vehicle(s) selected',
                          style: TextStyle(
                            color:
                                widget.selectedVehicles.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Clear capacity check button
        if (_selectedVehicleForCapacityCheck != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedVehicleForCapacityCheck = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear capacity check'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                // Show if this vehicle is already selected
                if (widget.selectedVehicles.any(
                  (v) => v.id == _selectedVehicleForCapacityCheck?.id,
                ))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Display selected vehicles with remove option
        if (widget.selectedVehicles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Vehicles:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.selectedVehicles.map((vehicle) {
                        return Chip(
                          label: Text(
                            vehicle.plateNo ??
                                '${vehicle.make} ${vehicle.name}',
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            final updatedList = List<DeliveryVehicleModel>.from(
                              widget.selectedVehicles,
                            );
                            updatedList.remove(vehicle);
                            widget.onVehiclesChanged(updatedList);
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
