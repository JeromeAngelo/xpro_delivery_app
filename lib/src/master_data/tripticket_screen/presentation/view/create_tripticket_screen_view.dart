import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart'
    show TripModel;
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_buttons.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';

// Personnel related imports
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';

// Checklist related imports
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/presentation/bloc/checklist_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:go_router/go_router.dart';

// Core utilities
import 'package:xpro_delivery_admin_app/core/services/core_utils.dart';

// Form widgets
import '../widget/create_trip_ticket_forms/trip_details_form.dart';
import '../widget/create_trip_ticket_forms/trip_vehicle_forms.dart';
import '../widget/create_trip_ticket_forms/trip_personnel_form.dart';
import '../widget/create_trip_ticket_forms/trip_checklist_form.dart';

class CreateTripTicketScreenView extends StatefulWidget {
  const CreateTripTicketScreenView({super.key});

  @override
  State<CreateTripTicketScreenView> createState() =>
      _CreateTripTicketScreenViewState();
}

class _CreateTripTicketScreenViewState
    extends State<CreateTripTicketScreenView> {
  final _formKey = GlobalKey<FormState>();
  final _tripIdController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _tripNameController = TextEditingController();

  // Selected items - Updated to use new models
  List<DeliveryDataModel> _selectedDeliveries = [];
  DeliveryVehicleModel? _selectedVehicle;
  List<PersonelModel> _selectedPersonnel = [];
  List<ChecklistModel> _selectedChecklists = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _generateTripIdAndQrCode();
    _loadData();
  }

  @override
  void dispose() {
    _tripIdController.dispose();
    _qrCodeController.dispose();
    _tripNameController.dispose();
    super.dispose();
  }

  void _generateTripIdAndQrCode() {
    // Generate a unique trip ID based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tripId = 'TRIP-$timestamp';

    // Set the trip ID
    _tripIdController.text = tripId;

    // Use the same value for QR code
    _qrCodeController.text = tripId;

    debugPrint('Generated Trip ID: $tripId');
    debugPrint('Generated QR Code: ${_qrCodeController.text}');
  }

  // Function to create a trip ticket
  void _createTripTicket() {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
      CoreUtils.showSnackBar(context, 'Please fill all required fields');
      return;
    }

    // // Validate required selections
    // if (_selectedDeliveries.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please add at least one delivery'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    if (_selectedVehicle == null) {
      CoreUtils.showSnackBar(context, 'Please select a vehicle');
      return;
    }

    if (_selectedPersonnel.isEmpty) {
      CoreUtils.showSnackBar(context, 'Please select at least one personnel');
      return;
    }

    // Check if more than 2 personnel are selected
    if (_selectedPersonnel.length > 3) {
      CoreUtils.showSnackBar(context, 'Maximum of 3 personnel allowed');
      return;
    }

    // Set loading state
    setState(() {
      _errorMessage = null;
      _hasNavigated = false;
    });

    // Create trip model with the selected data
    final tripModel = TripModel(
      tripNumberId: _tripIdController.text,
      name: _tripNameController.text.trim().isEmpty ? null : _tripNameController.text.trim(),
      qrCode: _qrCodeController.text,
      vehicleModel: _selectedVehicle,
      deliveryDataList: _selectedDeliveries,
      personelsList: _selectedPersonnel,
      checklistItems: _selectedChecklists,
    );

    // Dispatch the create event
    debugPrint(
      '🚀 Dispatching CreateTripTicketEvent for trip: ${tripModel.tripNumberId}',
    );
    context.read<TripBloc>().add(CreateTripTicketEvent(tripModel));
  }

  void _loadData() {
    // Load all required data using BLoCs
    context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataEvent());
    context.read<DeliveryVehicleBloc>().add(
      const LoadAllDeliveryVehiclesEvent(),
    );
    context.read<PersonelBloc>().add(GetPersonelEvent());
    context.read<ChecklistBloc>().add(const GetAllChecklistsEvent());
  }



  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return BlocConsumer<TripBloc, TripState>(
    listenWhen: (previous, current) {
        // Only listen to specific states to avoid unnecessary triggers
        return current is TripLoading ||
        current is TripTicketCreated ||
          current is TripError ||
          (current is AllTripTicketsLoaded && _isLoading && !_hasNavigated);
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
        } else if (state is TripTicketCreated) {
          debugPrint(
            '✅ Trip ticket created successfully: ${state.trip.tripNumberId}',
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
          'Trip ticket ${state.trip.tripNumberId} created successfully',
          );

            // Navigate back to trip tickets list immediately
            context.go('/tripticket');
          }
        } else if (state is AllTripTicketsLoaded && _isLoading && !_hasNavigated) {
          debugPrint('✅ All trip tickets loaded - processing as trip creation success');
          
          if (mounted) {
            setState(() {
    _isLoading = false;
            _errorMessage = null;
            _hasNavigated = true;
            });

            // Show success message and navigate
            CoreUtils.showSnackBar(
              context,
              'Trip ticket created successfully',
            );
            
            context.go('/tripticket');
          }
        } else if (state is TripError) {
          debugPrint('❌ Trip creation error: ${state.message}');
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
              title: 'Create Trip Ticket',
              actions: [
                // Cancel Button
                FormCancelButton(
                  label: 'Cancel',
                  onPressed: () {
                    if (!_isLoading) {
                      // Navigate back to trip tickets list
                      context.go('/tripticket');
                    }
                  },
                ),
                const SizedBox(width: 16),

                // Create Trip Button
                FormSubmitButton(
                  label: _isLoading ? 'Processing...' : 'Create Trip',
                  onPressed: () {
                    debugPrint(
                      '🔲 Create Trip Button Pressed - Loading: $_isLoading',
                    );
                    if (!_isLoading) {
                      _createTripTicket();
                    }
                  },
                  icon: _isLoading ? Icons.hourglass_empty : Icons.add,
                ),
              ],
              children: [
                // Trip Details Form
                _buildTripDetailsForm(),

                const SizedBox(height: 24),

                // Vehicle Form
                _buildVehicleForm(),

                const SizedBox(height: 24),

                // Personnel Form
                _buildPersonnelForm(),

                const SizedBox(height: 24),

                // Checklist Form
                _buildChecklistForm(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetailsForm() {
    return TripDetailsForm(
      tripIdController: _tripIdController,
      qrCodeController: _qrCodeController,
      tripNameController: _tripNameController,
      selectedCustomers: const [], // Not used anymore
      selectedInvoices: const [], // Not used anymore
      onCustomersChanged: (_) {}, // Not used anymore
      onInvoicesChanged: (_) {}, // Not used anymore
      onDeliveriesChanged: (deliveries) {
        setState(() {
          _selectedDeliveries = deliveries;
        });
      },
    );
  }

  Widget _buildVehicleForm() {
    return BlocBuilder<DeliveryVehicleBloc, DeliveryVehicleState>(
      builder: (context, state) {
        List<DeliveryVehicleModel> availableVehicles = [];

        if (state is DeliveryVehiclesLoaded) {
          availableVehicles = state.vehicles as List<DeliveryVehicleModel>;
        }

        return VehicleForm(
          availableVehicles: availableVehicles,
          selectedVehicles: _selectedVehicle != null ? [_selectedVehicle!] : [],
          onVehiclesChanged: (vehicles) {
            setState(() {
              _selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
            });
          },
        );
      },
    );
  }

  Widget _buildPersonnelForm() {
    return BlocBuilder<PersonelBloc, PersonelState>(
      builder: (context, state) {
        List<PersonelModel> availablePersonnel = [];

        if (state is PersonelLoaded) {
          availablePersonnel = state.personel as List<PersonelModel>;
        }

        return PersonnelForm(
          availablePersonnel: availablePersonnel,
          selectedPersonnel: _selectedPersonnel,
          onPersonnelChanged: (personnel) {
            setState(() {
              _selectedPersonnel = personnel;
            });
          },
        );
      },
    );
  }

  Widget _buildChecklistForm() {
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      builder: (context, state) {
        List<ChecklistModel> availableChecklists = [];

        if (state is AllChecklistsLoaded) {
          availableChecklists = state.checklists as List<ChecklistModel>;
        }

        return ChecklistForm(
          availableChecklists: availableChecklists,
          selectedChecklists: _selectedChecklists,
          onChecklistsChanged: (checklists) {
            setState(() {
              _selectedChecklists = checklists;
            });
          },
        );
      },
    );
  }
}
