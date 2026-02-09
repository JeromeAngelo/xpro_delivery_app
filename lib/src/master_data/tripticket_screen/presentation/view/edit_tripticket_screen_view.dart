import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart'
    show TripModel;
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_buttons.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';

// Personnel related imports
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';

// Checklist related imports
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:go_router/go_router.dart';

// Core utilities
import 'package:xpro_delivery_admin_app/core/services/core_utils.dart';

// Form widgets - Edit specific
import '../widget/edit_tripticket_forms/edit_trip_delivery_form.dart';
import '../widget/edit_tripticket_forms/edit_trip_vehicle_form.dart';
import '../widget/edit_tripticket_forms/edit_trip_personnel_form.dart';
import '../widget/edit_tripticket_forms/edit_trip_checklist_form.dart';

class EditTripTicketScreenView extends StatefulWidget {
  final String? tripId;
  final TripEntity? trip;

  const EditTripTicketScreenView({super.key, this.tripId, this.trip})
    : assert(
        tripId != null || trip != null,
        'Either tripId or trip must be provided',
      );

  @override
  State<EditTripTicketScreenView> createState() =>
      _EditTripTicketScreenViewState();
}

class _EditTripTicketScreenViewState extends State<EditTripTicketScreenView> {
  final _formKey = GlobalKey<FormState>();
  final _tripIdController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _tripNameController = TextEditingController();

  // Selected items - Updated to use new models
  List<DeliveryDataModel> _selectedDeliveries = [];
  DeliveryVehicleModel? _selectedVehicle;
  List<PersonelModel> _selectedPersonnel = [];
  List<ChecklistModel> _selectedChecklists = [];

  //Date and time
  DateTime? _deliveryDate;
  DateTime? _expectedReturnDate;

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNavigated = false;
  TripEntity? _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;

    if (widget.trip != null) {
      // If trip is provided directly, initialize with existing data
      _initializeWithExistingData();
    } else if (widget.tripId != null) {
      // If only tripId is provided, load the trip first
      context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId!));
    }
  }

  @override
  void dispose() {
    _tripIdController.dispose();
    _qrCodeController.dispose();
    _tripNameController.dispose();
    super.dispose();
  }

  void _initializeWithExistingData() {
    if (_currentTrip == null) return;

    // Pre-fill form fields with existing trip data
    _tripIdController.text = _currentTrip!.tripNumberId ?? '';
    _qrCodeController.text = _currentTrip!.qrCode ?? '';
    _tripNameController.text = _currentTrip!.name ?? '';
    // ✅ NEW: initialize delivery/return dates (this makes UI show existing values)
  _deliveryDate = _currentTrip!.deliveryDate;
  _expectedReturnDate = _currentTrip!.expectedReturnDate;

    // Initialize with actual trip data instead of empty collections
    if (_currentTrip!.deliveryData.isNotEmpty) {
      _selectedDeliveries =
          _currentTrip!.deliveryData
              .map(
                (delivery) => DeliveryDataModel(
                  id: delivery.id,
                  collectionId: delivery.collectionId,
                  collectionName: delivery.collectionName,
                  deliveryNumber: delivery.deliveryNumber,
                  hasTrip: delivery.hasTrip,
                  created: delivery.created,
                  updated: delivery.updated,
                ),
              )
              .toList();
    }

    if (_currentTrip!.vehicle != null) {
      _selectedVehicle = DeliveryVehicleModel(
        id: _currentTrip!.vehicle!.id,
        collectionId: _currentTrip!.vehicle!.collectionId,
        collectionName: _currentTrip!.vehicle!.collectionName,
        name: _currentTrip!.vehicle!.name,
        plateNo: _currentTrip!.vehicle!.plateNo,
        make: _currentTrip!.vehicle!.make,
        type: _currentTrip!.vehicle!.type,
        wheels: _currentTrip!.vehicle!.wheels,
        volumeCapacity: _currentTrip!.vehicle!.volumeCapacity,
        weightCapacity: _currentTrip!.vehicle!.weightCapacity,
        created: _currentTrip!.vehicle!.created,
        updated: _currentTrip!.vehicle!.updated,
      );
    }

    if (_currentTrip!.personels.isNotEmpty) {
      _selectedPersonnel =
          _currentTrip!.personels
              .map(
                (personnel) => PersonelModel(
                  id: personnel.id,
                  collectionId: personnel.collectionId,
                  collectionName: personnel.collectionName,
                  name: personnel.name,
                  role: personnel.role,
                  isAssigned: personnel.isAssigned,
                  deliveryTeamModel: personnel.deliveryTeam,
                  created: personnel.created,
                  updated: personnel.updated,
                ),
              )
              .toList();
    }

    if (_currentTrip!.checklist.isNotEmpty) {
      _selectedChecklists =
          _currentTrip!.checklist
              .map(
                (checklist) => ChecklistModel(
                  id: checklist.id,
                  objectName: checklist.objectName,
                  status: checklist.status,
                  isChecked: checklist.isChecked,
                  timeCompleted: checklist.timeCompleted,
                ),
              )
              .toList();
    }

    debugPrint(
      '🔄 Initialized edit form with trip: ${_currentTrip!.tripNumberId}',
    );
    debugPrint(
      '📦 Trip has ${_currentTrip!.deliveryData.length} deliveries -> Selected: ${_selectedDeliveries.length}',
    );
    debugPrint(
      '🚗 Trip has vehicle: ${_currentTrip!.vehicle?.name ?? 'None'} -> Selected: ${_selectedVehicle?.name ?? 'None'}',
    );
    debugPrint(
      '👥 Trip has ${_currentTrip!.personels.length} personnel -> Selected: ${_selectedPersonnel.length}',
    );
    debugPrint(
      '📋 Trip has ${_currentTrip!.checklist.length} checklists -> Selected: ${_selectedChecklists.length}',
    );
  }

  // Function to update a trip ticket
  void _updateTripTicket() {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
      CoreUtils.showSnackBar(context, 'Please fill all required fields');
      return;
    }

    if (_selectedVehicle == null) {
      CoreUtils.showSnackBar(context, 'Please select a vehicle');
      return;
    }

    if (_selectedPersonnel.isEmpty) {
      CoreUtils.showSnackBar(context, 'Please select at least one personnel');
      return;
    }

    // Check if more than 3 personnel are selected
    if (_selectedPersonnel.length > 3) {
      CoreUtils.showSnackBar(context, 'Maximum of 3 personnel allowed');
      return;
    }
    // Check if more than 3 personnel are selected
    if (_deliveryDate == null) {
      CoreUtils.showSnackBar(context, 'Please select a delivery date');
      return;
    }

    if (_expectedReturnDate == null) {
      CoreUtils.showSnackBar(context, 'Please select an expected return date');
      return;
    }
    // Set loading state
    setState(() {
      _errorMessage = null;
      _hasNavigated = false;
    });

    // Create updated trip model with the selected data
    final updatedTripModel = TripModel(
      id: _currentTrip?.id, // Keep the original ID
      tripNumberId: _tripIdController.text,
      name:
          _tripNameController.text.trim().isEmpty
              ? null
              : _tripNameController.text.trim(),
      qrCode: _qrCodeController.text,
      vehicleModel: _selectedVehicle,
      deliveryDataList: _selectedDeliveries,
      personelsList: _selectedPersonnel,
      checklistItems: _selectedChecklists,
      deliveryDate: _deliveryDate,
      expectedReturnDate: _expectedReturnDate,
      // Preserve other existing data
      timeAccepted: _currentTrip?.timeAccepted,
      timeEndTrip: _currentTrip?.timeEndTrip,
      totalTripDistance: _currentTrip?.totalTripDistance,
    );

    // Dispatch the update event
    debugPrint(
      '🔄 Dispatching UpdateTripTicketEvent for trip: ${updatedTripModel.tripNumberId}',
    );
    context.read<TripBloc>().add(UpdateTripTicketEvent(updatedTripModel));
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return BlocConsumer<TripBloc, TripState>(
      listenWhen: (previous, current) {
        // Only listen to specific states to avoid unnecessary triggers
        return current is TripLoading ||
            current is TripTicketLoaded ||
            current is TripTicketUpdated ||
            current is TripError;
      },
      listener: (context, state) {
        debugPrint('🔄 TripBloc State Changed: ${state.runtimeType}');

        if (state is TripLoading) {
          debugPrint('📤 Trip loading state received');
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
        } else if (state is TripTicketLoaded) {
          debugPrint('✅ Trip ticket loaded: ${state.trip.tripNumberId}');
          if (mounted) {
            setState(() {
              _currentTrip = state.trip;
              _isLoading = false;
            });
            _initializeWithExistingData();
          }
        } else if (state is TripTicketUpdated) {
          debugPrint(
            '✅ Trip ticket updated successfully: ${state.trip.tripNumberId}',
          );
          if (mounted && !_hasNavigated) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
              _hasNavigated = true;
            });

            // Show success message
            CoreUtils.showSnackBar(
              context,
              'Trip ticket ${state.trip.tripNumberId} updated successfully',
            );

            // Navigate back to trip details view
            final tripId = _currentTrip?.id ?? widget.tripId;
            context.go('/tripticket/$tripId');
          }
        } else if (state is TripError) {
          debugPrint('❌ Trip update error: ${state.message}');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });

            // Show error message
            CoreUtils.showSnackBar(context, 'Error: ${state.message}');
          }
        }
      },
      builder: (context, state) {
        return DesktopLayout(
          navigationItems: navigationItems,
          currentRoute: '/tripticket',
          onNavigate: (route) {
            // Handle navigation
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
          child: Form(
            key: _formKey,
            child: FormLayout(
              title:
                  'Edit Trip Ticket: ${_currentTrip?.tripNumberId ?? 'Loading...'}',
              actions: [
                // Cancel Button
                FormCancelButton(
                  label: 'Cancel',
                  onPressed: () {
                    if (!_isLoading) {
                      // Navigate back to trip details
                      final tripId = _currentTrip?.id ?? widget.tripId;
                      context.go('/tripticket/$tripId');
                    }
                  },
                ),
                const SizedBox(width: 16),

                // Update Trip Button
                FormSubmitButton(
                  label: _isLoading ? 'Updating...' : 'Update Trip',
                  onPressed: () {
                    debugPrint(
                      '🔲 Update Trip Button Pressed - Loading: $_isLoading',
                    );
                    if (!_isLoading) {
                      _updateTripTicket();
                    }
                  },
                  icon: _isLoading ? Icons.hourglass_empty : Icons.update,
                ),
              ],
              children: [
                // Trip Details Section (Trip ID and QR Code)
                _buildTripDetailsSection(),

                const SizedBox(height: 24),

                // Delivery Data Form
                EditTripDeliveryForm(
                  currentTrip: _currentTrip,
                  tripId: widget.tripId,
                  selectedDeliveries: _selectedDeliveries,
                  onDeliveriesChanged: (deliveries) {
                    setState(() {
                      _selectedDeliveries = deliveries;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Vehicle Form
                EditTripVehicleForm(
                  currentTrip: _currentTrip,
                  tripId: widget.tripId,
                  selectedVehicle: _selectedVehicle,
                  onVehicleChanged: (vehicle) {
                    setState(() {
                      _selectedVehicle = vehicle;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Personnel Form
                EditTripPersonnelForm(
                  currentTrip: _currentTrip,
                  tripId: widget.tripId,
                  selectedPersonnel: _selectedPersonnel,
                  onPersonnelChanged: (personnel) {
                    setState(() {
                      _selectedPersonnel = personnel;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Checklist Form
                EditTripChecklistForm(
                  currentTrip: _currentTrip,
                  selectedChecklists: _selectedChecklists,
                  onChecklistsChanged: (checklists) {
                    setState(() {
                      _selectedChecklists = checklists;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 24),
                SizedBox(width: 8),
                Text(
                  'Trip Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // First row: Trip ID and QR Code
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tripIdController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Number ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Trip Number ID is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _qrCodeController,
                    decoration: const InputDecoration(
                      labelText: 'QR Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'QR Code is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Second row: Trip Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tripNameController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Name (Optional)',
                      hintText: 'Enter trip name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: null,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Third row: Delivery Date + Expected Return Date (editable)
            _buildDeliveryDateForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDateForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Date Section
          Expanded(
            child: _buildDatePickerField(
              label: 'Delivery Date',
              date: _deliveryDate,
              onPickDate: (picked) {
                setState(() => _deliveryDate = picked);
              },
              onClear: () {
                setState(() => _deliveryDate = null);
              },
            ),
          ),

          const SizedBox(width: 24),

          // Expected Return Date Section
          Expanded(
            child: _buildDatePickerField(
              label: 'Expected Return Date',
              date: _expectedReturnDate,
              onPickDate: (picked) {
                setState(() => _expectedReturnDate = picked);
              },
              onClear: () {
                setState(() => _expectedReturnDate = null);
              },
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MM/dd/yyyy hh:mm a').format(date);
  }

  /// Reusable date picker field widget
  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPickDate,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2050),
                  );
                  if (pickedDate != null) onPickDate(pickedDate);
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      date != null
                          ? DateFormat('MM/dd/yyyy').format(date)
                          : 'Select $label',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Clear $label',
            ),
          ],
        ),
      ],
    );
  }
}
