import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/entity/invoice_preset_group_entity.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

class SummaryDeliveryDataDialog extends StatefulWidget {
  final String tripId;
  final List<InvoicePresetGroupEntity> selectedPresetGroups;
  final VoidCallback? onConfirmed;

  const SummaryDeliveryDataDialog({
    super.key,
    required this.tripId,
    required this.selectedPresetGroups,
    this.onConfirmed,
  });

  @override
  State<SummaryDeliveryDataDialog> createState() =>
      _SummaryDeliveryDataDialogState();
}

class _SummaryDeliveryDataDialogState extends State<SummaryDeliveryDataDialog> {
  bool _isProcessing = false;
  int _processedPresetGroups = 0;
  int _totalPresetGroups = 0;

  @override
  void initState() {
    super.initState();
    // Load trip data when dialog opens
    _loadTripData();
  }

  void _loadTripData() {
    context.read<TripBloc>().add(GetTripTicketByIdEvent(widget.tripId));
    debugPrint('🔄 Loading trip data for trip ID: ${widget.tripId}');
  }

  void _closeDialog() {
    if (mounted && !_isProcessing) {
      context.pop();
    }
  }

  void _confirmAddDeliveryData() {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processedPresetGroups = 0;
      _totalPresetGroups = widget.selectedPresetGroups.length;
    });

    debugPrint('🔄 Starting to create delivery data from $_totalPresetGroups preset groups');

    // Step 1: Create delivery data from selected preset groups
    // For now, we'll use the addDeliveryDataToTrip method directly
    // This will create delivery data and assign it to the trip
    _createDeliveryDataAndAddToTrip();
  }

  void _createDeliveryDataAndAddToTrip() {
    // Create delivery data and add to trip
    // The addDeliveryDataToTrip function will:
    // 1. Find available delivery data (hasTrip = false)
    // 2. Assign it to the trip
    
    context.read<DeliveryDataBloc>().add(
      AddDeliveryDataToTripEvent(widget.tripId),
    );

    debugPrint('🔄 Adding delivery data to trip ID: ${widget.tripId}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryDataBloc, DeliveryDataState>(
      listener: (context, deliveryState) {
        if (deliveryState is DeliveryDataAddedToTrip) {
          setState(() {
            _isProcessing = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery data added to trip successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Call the callback if provided
          if (widget.onConfirmed != null) {
            widget.onConfirmed!();
          }

          // Close the dialog
          _closeDialog();
        } else if (deliveryState is DeliveryDataError) {
          setState(() {
            _isProcessing = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${deliveryState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.summarize, size: 28, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Delivery Data Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_isProcessing)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeDialog,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Trip Information
              _buildTripInfoSection(),

              const SizedBox(height: 24),

              // Selected Preset Groups Section
              _buildSelectedPresetsSection(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfoSection() {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Trip Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (state is TripLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is TripTicketLoaded)
                  _buildTripDetails(state.trip)
                else if (state is TripError)
                  Text(
                    'Error loading trip: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  _buildTripIdFallback(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetails(dynamic trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Trip ID:', widget.tripId),
        if (trip.tripNumberId != null)
          _buildInfoRow('Trip Number:', trip.tripNumberId.toString()),
        if (trip.qrCode != null)
          _buildInfoRow('QR Code:', trip.qrCode.toString()),
        _buildInfoRow(
          'Status:',
          trip.isAccepted == true ? 'Accepted' : 'Pending',
        ),
        if (trip.isEndTrip == true) _buildInfoRow('Trip Status:', 'Completed'),
        if (trip.deliveryData != null)
          _buildInfoRow('Current Deliveries:', '${trip.deliveryData.length}'),
      ],
    );
  }

  Widget _buildTripIdFallback() {
    return _buildInfoRow('Trip ID:', widget.tripId);
  }

  Widget _buildSelectedPresetsSection() {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.playlist_add_check, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Preset Groups (${widget.selectedPresetGroups.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child:
                    widget.selectedPresetGroups.isEmpty
                        ? const Center(
                          child: Text(
                            'No preset groups selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.separated(
                          itemCount: widget.selectedPresetGroups.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final presetGroup =
                                widget.selectedPresetGroups[index];
                            return _buildPresetGroupCard(
                              presetGroup,
                              index + 1,
                            );
                          },
                        ),
              ),

              // Summary footer
              if (widget.selectedPresetGroups.isNotEmpty) _buildSummaryFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGroupCard(
    InvoicePresetGroupEntity presetGroup,
    int index,
  ) {
    final totalAmount = presetGroup.invoices.fold<double>(
      0,
      (sum, invoice) => sum + (invoice.totalAmount ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presetGroup.name ?? 'Unknown Preset Group',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (presetGroup.refId != null)
                      Text(
                        'Ref ID: ${presetGroup.refId}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                '${presetGroup.invoices.length} invoices',
                Icons.receipt,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                '₱${totalAmount.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildSummaryFooter() {
    final totalInvoices = widget.selectedPresetGroups.fold<int>(
      0,
      (sum, group) => sum + group.invoices.length,
    );

    final totalAmount = widget.selectedPresetGroups.fold<double>(
      0,
      (sum, group) =>
          sum +
          group.invoices.fold<double>(
            0,
            (invoiceSum, invoice) => invoiceSum + (invoice.totalAmount ?? 0),
          ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '$totalInvoices invoices • ₱${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        const Spacer(),
        TextButton(
          onPressed: _isProcessing ? null : _closeDialog,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isProcessing ? null : _confirmAddDeliveryData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_totalPresetGroups > 0 
                        ? 'Processing ($_processedPresetGroups/$_totalPresetGroups)...'
                        : 'Processing...'),
                  ],
                )
              : const Text('Confirm Add to Trip'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
