import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/entity/invoice_preset_group_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_state.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/create_trip_ticket_forms/processing_loading_widget.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/edit_tripticket_forms/summary_delivery_data_dialog.dart';

class UpdatePresetGroupDialog extends StatefulWidget {
  final String? tripId;
  final VoidCallback? onPresetAdded;

  const UpdatePresetGroupDialog({
    super.key,
    this.tripId,
    this.onPresetAdded,
  });

  @override
  State<UpdatePresetGroupDialog> createState() =>
      _UpdatePresetGroupDialogState();
}

class _UpdatePresetGroupDialogState extends State<UpdatePresetGroupDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<InvoicePresetGroupEntity> _selectedPresetGroups = [];
  int _processedPresetGroups = 0;
  bool _isCreatingDeliveryData = false;

  @override
  void initState() {
    super.initState();
    // Load all preset groups when the dialog opens
    _loadPresetGroups();
  }

  // Extract loading logic to a separate method
  void _loadPresetGroups() {
    context.read<InvoicePresetGroupBloc>().add(
      const GetAllUnassignedInvoicePresetGroupsEvent(),
    );
  }

  void _closeDialog() {
    if (mounted && !_isCreatingDeliveryData) {
      // Use GoRouter to pop the dialog instead of Navigator
      context.pop();
    }
  }

  void _togglePresetGroupSelection(InvoicePresetGroupEntity presetGroup) {
    setState(() {
      if (_selectedPresetGroups.contains(presetGroup)) {
        _selectedPresetGroups.remove(presetGroup);
      } else {
        _selectedPresetGroups.add(presetGroup);
      }
    });
  }

  void _addSelectedPresetsToDelivery() {
    if (_selectedPresetGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preset group'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ID is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Start creating delivery data from selected preset groups
    _createDeliveryDataFromPresets();
  }

  void _createDeliveryDataFromPresets() {
    setState(() {
      _isCreatingDeliveryData = true;
      _processedPresetGroups = 0;
    });

    debugPrint('🔄 Creating delivery data from ${_selectedPresetGroups.length} preset groups');

    // Create delivery data for each selected preset group
    for (int i = 0; i < _selectedPresetGroups.length; i++) {
      final presetGroup = _selectedPresetGroups[i];
      
      debugPrint('🔄 Creating delivery data for preset group: ${presetGroup.name} (${presetGroup.id})');
      
      // Trigger the event to add invoices to delivery (this will create delivery data)
      context.read<InvoicePresetGroupBloc>().add(
        AddAllInvoicesToDeliveryEvent(
          presetGroupId: presetGroup.id!,
          deliveryId: '', // Empty string to indicate auto-generation in the remote data source
        ),
      );
    }
  }

  void _showSummaryDialog() {
    // Close this dialog first
    _closeDialog();
    
    // Show summary dialog with selected preset groups
    showDialog(
      context: context,
      builder: (context) => SummaryDeliveryDataDialog(
        tripId: widget.tripId!,
        selectedPresetGroups: _selectedPresetGroups,
        onConfirmed: () {
          // Callback when delivery data is added to trip
          if (widget.onPresetAdded != null) {
            widget.onPresetAdded!();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoicePresetGroupBloc, InvoicePresetGroupState>(
      listener: (context, state) {
        if (state is InvoicesAddedToDelivery) {
          // Increment processed count
          setState(() {
            _processedPresetGroups++;
          });

          debugPrint('🔄 Processed $_processedPresetGroups/${_selectedPresetGroups.length} preset groups');

          // Check if all preset groups have been processed
          if (_processedPresetGroups >= _selectedPresetGroups.length) {
            setState(() {
              _isCreatingDeliveryData = false;
            });

            debugPrint('✅ All delivery data created, showing summary dialog');

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery data created successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // Now show summary dialog
            _showSummaryDialog();
          }
        } else if (state is InvoicePresetGroupError && _isCreatingDeliveryData) {
          setState(() {
            _isCreatingDeliveryData = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating delivery data: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.playlist_add_check, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Select Invoice Preset Groups',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_selectedPresetGroups.isNotEmpty)
                    Chip(
                      label: Text('${_selectedPresetGroups.length} selected'),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  const SizedBox(width: 8),
                  if (!_isCreatingDeliveryData)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeDialog,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Ref ID or Name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {}); // Trigger rebuild to clear search
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted:
                    (_) => setState(() {}), // Trigger rebuild on submit
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild on every change
                },
              ),

              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<
                  InvoicePresetGroupBloc,
                  InvoicePresetGroupState
                >(
                  builder: (context, state) {
                    if (state is InvoicePresetGroupLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is InvoiceProcessingToDelivery) {
                      return ProcessingLoadingWidget(
                        message: 'Processing invoices to delivery...',
                        currentInvoiceId: state.currentInvoiceId,
                        currentProcessMessage: state.currentProcessMessage,
                        currentIndex: state.currentIndex,
                        totalInvoices: state.totalInvoices,
                        onCancel: () {
                          context.pop();
                        },
                      );
                    }

                    if (state is InvoicePresetGroupError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPresetGroups,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is AllUnassignedInvoicePresetGroupsLoaded) {
                      var presetGroups = state.presetGroups;

                      // Apply local search filtering
                      if (_searchController.text.trim().isNotEmpty) {
                        final query =
                            _searchController.text.trim().toLowerCase();
                        presetGroups =
                            presetGroups.where((group) {
                              return (group.name?.toLowerCase().contains(
                                        query,
                                      ) ??
                                      false) ||
                                  (group.refId?.toLowerCase().contains(query) ??
                                      false);
                            }).toList();
                      }

                      if (presetGroups.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.trim().isNotEmpty
                                    ? 'No preset groups found matching "${_searchController.text.trim()}"'
                                    : 'No preset groups found',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Add debug print to verify data
                      debugPrint(
                        '🔍 Displaying ${presetGroups.length} preset groups (filtered from ${state.presetGroups.length})',
                      );
                      for (var group in presetGroups) {
                        debugPrint(
                          '  - Group: ${group.name} (${group.refId}) with ${group.invoices.length} invoices',
                        );
                      }

                      return _buildPresetGroupsList(presetGroups);
                    }

                    return const Center(
                      child: Text('Select preset groups to add to trip'),
                    );
                  },
                ),
              ),
              
              // Action buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: !_isCreatingDeliveryData ? _closeDialog : null,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: (_selectedPresetGroups.isNotEmpty && !_isCreatingDeliveryData) 
                        ? _addSelectedPresetsToDelivery 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isCreatingDeliveryData
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
                              Text(
                                'Creating Delivery Data ($_processedPresetGroups/${_selectedPresetGroups.length})...',
                              ),
                            ],
                          )
                        : Text(
                            'Add Selected Presets to Delivery (${_selectedPresetGroups.length})',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGroupsList(List<InvoicePresetGroupEntity> presetGroups) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        itemCount: presetGroups.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final presetGroup = presetGroups[index];
          final isSelected = _selectedPresetGroups.contains(presetGroup);
          
          return Container(
            color: isSelected ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: Checkbox(
                value: isSelected,
                onChanged: (value) => _togglePresetGroupSelection(presetGroup),
              ),
              title: Text(
                presetGroup.name ?? 'Unknown Preset Group',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (presetGroup.refId != null)
                    Text('Ref ID: ${presetGroup.refId}'),
                  Text('${presetGroup.invoices.length} invoices'),
                  if (presetGroup.invoices.isNotEmpty)
                    Text(
                      'Total Amount: ₱${presetGroup.invoices.fold<double>(0, (sum, invoice) => sum + (invoice.totalAmount ?? 0)).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              trailing: isSelected 
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              onTap: () => _togglePresetGroupSelection(presetGroup),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
