import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/edit_tripticket_forms/update_preset_group_dialog.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/customer_data_dialog.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/edit_tripticket_forms/add_delivery_dialog.dart';

class EditTripDeliveryForm extends StatefulWidget {
  final TripEntity? currentTrip;
  final String? tripId;
  final List<DeliveryDataModel> selectedDeliveries;
  final Function(List<DeliveryDataModel>) onDeliveriesChanged;

  const EditTripDeliveryForm({
    super.key,
    this.currentTrip,
    this.tripId,
    required this.selectedDeliveries,
    required this.onDeliveriesChanged,
  });

  @override
  State<EditTripDeliveryForm> createState() => _EditTripDeliveryFormState();
}

class _EditTripDeliveryFormState extends State<EditTripDeliveryForm> {
  List<DeliveryDataModel> _availableDeliveries = [];
  List<DeliveryDataModel> _tripDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripDeliveryData();
    _loadAllDeliveryData();
  }

  void _loadTripDeliveryData() {
    // Load delivery data specific to this trip
    final tripIdToUse = widget.tripId ?? widget.currentTrip?.id;
    if (tripIdToUse != null) {
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByTripIdEvent(tripIdToUse),
      );
      debugPrint('🔄 Loading delivery data for trip ID: $tripIdToUse');
    } else {
      // Fallback to existing data if no trip ID available
      _initializeWithExistingData();
    }
  }

  void _loadAllDeliveryData() {
    // Load all available deliveries for potential addition
    context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataEvent());
    debugPrint('📦 Loading all delivery data for selection dialog');
  }

  void _initializeWithExistingData() {
    // Fallback initialization with existing trip delivery data
    if (widget.currentTrip?.deliveryData != null &&
        widget.currentTrip!.deliveryData.isNotEmpty) {
      _tripDeliveries =
          widget.currentTrip!.deliveryData
              .map(
                (delivery) => DeliveryDataModel(
                  id: delivery.id,
                  collectionId: delivery.collectionId,
                  collectionName: delivery.collectionName,
                  deliveryNumber: delivery.deliveryNumber,
                  hasTrip: delivery.hasTrip,
                  created: delivery.created,
                  updated: delivery.updated,
                  // Convert entities to models if they exist
                  customer:
                      delivery.customer != null
                          ? CustomerDataModel(
                            id: delivery.customer!.id,
                            collectionId: delivery.customer!.collectionId,
                            collectionName: delivery.customer!.collectionName,
                            name: delivery.customer!.name,
                            ownerName: delivery.customer!.ownerName,
                            paymentMode: delivery.customer!.paymentMode,
                            refId: delivery.customer!.refId,
                            contactNumber: delivery.customer!.contactNumber,
                            province: delivery.customer!.province,
                            municipality: delivery.customer!.municipality,
                            barangay: delivery.customer!.barangay,
                            longitude: delivery.customer!.longitude,
                            latitude: delivery.customer!.latitude,
                            created: delivery.customer!.created,
                            updated: delivery.customer!.updated,
                          )
                          : null,
                  invoice:
                      delivery.invoice != null
                          ? InvoiceDataModel(
                            id: delivery.invoice!.id,
                            collectionId: delivery.invoice!.collectionId,
                            collectionName: delivery.invoice!.collectionName,
                            name: delivery.invoice!.name,
                            refId: delivery.invoice!.refId,
                            documentDate: delivery.invoice!.documentDate,
                            totalAmount: delivery.invoice!.totalAmount,
                            volume: delivery.invoice!.volume,
                            weight: delivery.invoice!.weight,
                            created: delivery.invoice!.created,
                            updated: delivery.invoice!.updated,
                          )
                          : null,
                ),
              )
              .toList();

      setState(() {
        _isLoading = false;
      });

      // Notify parent immediately
      widget.onDeliveriesChanged(_tripDeliveries);

      debugPrint(
        '🔄 Initialized edit form with ${_tripDeliveries.length} existing deliveries',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listener: (context, state) {
        if (state is AllDeliveryDataLoaded) {
          setState(() {
            _availableDeliveries = state.deliveryData.cast<DeliveryDataModel>();
          });
          debugPrint(
            '📦 Loaded ${_availableDeliveries.length} available deliveries for selection',
          );
        } else if (state is DeliveryDataByTripLoaded) {
          // Handle trip-specific delivery data
          final tripIdToUse = widget.tripId ?? widget.currentTrip?.id;
          if (state.tripId == tripIdToUse) {
            _tripDeliveries =
                state.deliveryData
                    .map(
                      (delivery) => DeliveryDataModel(
                        id: delivery.id,
                        collectionId: delivery.collectionId,
                        collectionName: delivery.collectionName,
                        deliveryNumber: delivery.deliveryNumber,
                        hasTrip: delivery.hasTrip,
                        created: delivery.created,
                        updated: delivery.updated,
                        // Convert entities to models if they exist
                        customer:
                            delivery.customer != null
                                ? CustomerDataModel(
                                  id: delivery.customer!.id,
                                  collectionId: delivery.customer!.collectionId,
                                  collectionName:
                                      delivery.customer!.collectionName,
                                  name: delivery.customer!.name,
                                  ownerName: delivery.customer!.ownerName,
                                  paymentMode: delivery.customer!.paymentMode,
                                  refId: delivery.customer!.refId,
                                  contactNumber:
                                      delivery.customer!.contactNumber,
                                  province: delivery.customer!.province,
                                  municipality: delivery.customer!.municipality,
                                  barangay: delivery.customer!.barangay,
                                  longitude: delivery.customer!.longitude,
                                  latitude: delivery.customer!.latitude,
                                  created: delivery.customer!.created,
                                  updated: delivery.customer!.updated,
                                )
                                : null,
                        invoice:
                            delivery.invoice != null
                                ? InvoiceDataModel(
                                  id: delivery.invoice!.id,
                                  collectionId: delivery.invoice!.collectionId,
                                  collectionName:
                                      delivery.invoice!.collectionName,
                                  name: delivery.invoice!.name,
                                  refId: delivery.invoice!.refId,
                                  documentDate: delivery.invoice!.documentDate,
                                  totalAmount: delivery.invoice!.totalAmount,
                                  volume: delivery.invoice!.volume,
                                  weight: delivery.invoice!.weight,
                                  created: delivery.invoice!.created,
                                  updated: delivery.invoice!.updated,
                                )
                                : null,
                      ),
                    )
                    .toList();

            setState(() {
              _isLoading = false;
            });

            // Notify parent immediately
            widget.onDeliveriesChanged(_tripDeliveries);

            debugPrint(
              '🔄 Loaded ${_tripDeliveries.length} trip deliveries from BLoC',
            );
          }
        } else if (state is DeliveryDataDeleted) {
          // Handle successful deletion
          final deletedDelivery = _tripDeliveries.firstWhere(
            (delivery) => delivery.id == state.id,
            orElse: () => DeliveryDataModel(id: state.id),
          );
          
          setState(() {
            _tripDeliveries.removeWhere((delivery) => delivery.id == state.id);
            _isLoading = false;
          });
          
          // Notify parent of the updated list
          widget.onDeliveriesChanged(_tripDeliveries);
          
          debugPrint('✅ Removed delivery ${state.id} from trip deliveries list');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Delivery "${deletedDelivery.deliveryNumber ?? 'Unknown'}" successfully removed from trip',
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh trip delivery data to ensure consistency
          _loadTripDeliveryData();
          
        } else if (state is DeliveryDataError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading delivery data: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        // Handle loading state
        bool isLoading = _isLoading;
        if (state is DeliveryDataLoading) {
          isLoading = true;
        }

        return _buildContent(isLoading);
      },
    );
  }

  Widget _buildContent(bool isLoading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Trip Deliveries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: isLoading ? null : _showAddDeliveryChoiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Delivery'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_tripDeliveries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No deliveries assigned to this trip',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              _buildDeliveriesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _tripDeliveries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final delivery = _tripDeliveries[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              delivery.deliveryNumber ?? 'Unknown Delivery',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (delivery.customer?.name != null)
                  Text('Customer: ${delivery.customer!.name}'),
                if (delivery.customer?.municipality != null ||
                    delivery.customer?.province != null)
                  Text(
                    'Address: ${delivery.customer!.municipality ?? ''}, ${delivery.customer!.province ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (delivery.invoice?.refId != null)
                  Text('Invoice: ${delivery.invoice!.refId}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeDelivery(delivery),
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }

  void _removeDelivery(DeliveryDataModel delivery) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Delivery'),
            content: Text(
              'Are you sure you want to remove delivery "${delivery.deliveryNumber}" from this trip?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Dispatch delete event - the BlocListener will handle UI updates
                  context.read<DeliveryDataBloc>().add(
                    DeleteDeliveryDataEvent(delivery.id!),
                  );
                  Navigator.of(context).pop();
                  
                  // Show processing message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Removing delivery "${delivery.deliveryNumber}" from trip...',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _showAddDeliveryChoiceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Delivery'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose how you want to add delivery data:'),
                  const SizedBox(height: 20),

                  // Picklist option
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.playlist_add_check,
                        color: Colors.blue,
                      ),
                      title: const Text('Picklist'),
                      subtitle: const Text(
                        'Add deliveries from invoice preset groups',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showPicklistDialog();
                      },
                    ),
                  ),

                  // Customer option
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.people, color: Colors.green),
                      title: const Text('Customer'),
                      subtitle: const Text(
                        'Create deliveries from customer data',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showCustomerDialog();
                      },
                    ),
                  ),

                  // Existing delivery option
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.local_shipping,
                        color: Colors.orange,
                      ),
                      title: const Text('Existing Delivery'),
                      subtitle: const Text(
                        'Add existing unassigned deliveries',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showAddDeliveryDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showPicklistDialog() {
    final tripIdToUse = widget.tripId ?? widget.currentTrip?.id;

    if (tripIdToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ID is required to add delivery data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => UpdatePresetGroupDialog(
            tripId: tripIdToUse,
            onPresetAdded: () {
              // Refresh delivery data after preset is added
              _loadTripDeliveryData();
              _loadAllDeliveryData();
            },
          ),
    );
  }

  void _showCustomerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CustomerDataDialog(
            onCustomersSelected: (customers) {
              // Handle customer selection
              debugPrint(
                'Selected ${customers.length} customers for delivery creation',
              );
              // TODO: Implement delivery creation from customers
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Selected ${customers.length} customers. Delivery creation functionality will be implemented.',
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showAddDeliveryDialog() {
    // Filter out deliveries that are already in this trip
    final availableToAdd =
        _availableDeliveries
            .where(
              (delivery) =>
                  !_tripDeliveries.any((trip) => trip.id == delivery.id),
            )
            .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available deliveries to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddDeliveryDialog(
        tripId: widget.tripId ?? widget.currentTrip?.id,
        availableDeliveries: _availableDeliveries,
        tripDeliveries: _tripDeliveries,
        onDeliveriesAdded: (selectedDeliveries) {
          setState(() {
            _tripDeliveries.addAll(selectedDeliveries);
          });
          widget.onDeliveriesChanged(_tripDeliveries);
          
          // Refresh delivery data to ensure consistency
          _loadTripDeliveryData();
        },
      ),
    );
  }


}
