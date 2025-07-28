import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

class AddDeliveryDialog extends StatefulWidget {
  final String? tripId;
  final List<DeliveryDataModel> availableDeliveries;
  final List<DeliveryDataModel> tripDeliveries;
  final Function(List<DeliveryDataModel>) onDeliveriesAdded;

  const AddDeliveryDialog({
    super.key,
    this.tripId,
    required this.availableDeliveries,
    required this.tripDeliveries,
    required this.onDeliveriesAdded,
  });

  @override
  State<AddDeliveryDialog> createState() => _AddDeliveryDialogState();
}

class _AddDeliveryDialogState extends State<AddDeliveryDialog> {
  final Set<String> _selectedDeliveryIds = <String>{};
  List<DeliveryDataModel> _filteredDeliveries = [];
  final TextEditingController _searchController = TextEditingController();
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _filterDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDeliveries() {
    // Filter out deliveries that are already in the trip
    _filteredDeliveries = widget.availableDeliveries
        .where((delivery) =>
            !widget.tripDeliveries.any((tripDelivery) => tripDelivery.id == delivery.id))
        .where((delivery) {
          final searchQuery = _searchController.text.toLowerCase();
          if (searchQuery.isEmpty) return true;
          
          return (delivery.deliveryNumber?.toLowerCase().contains(searchQuery) ?? false) ||
                 (delivery.customer?.name?.toLowerCase().contains(searchQuery) ?? false) ||
                 (delivery.invoice?.refId?.toLowerCase().contains(searchQuery) ?? false);
        })
        .toList();

    // Update select all state
    _selectAll = _filteredDeliveries.isNotEmpty && 
                 _filteredDeliveries.every((delivery) => _selectedDeliveryIds.contains(delivery.id));
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedDeliveryIds.addAll(_filteredDeliveries.map((d) => d.id!));
      } else {
        _selectedDeliveryIds.removeWhere((id) => 
            _filteredDeliveries.any((d) => d.id == id));
      }
    });
  }

  void _toggleDeliverySelection(String deliveryId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedDeliveryIds.add(deliveryId);
      } else {
        _selectedDeliveryIds.remove(deliveryId);
      }
      
      // Update select all state
      _selectAll = _filteredDeliveries.isNotEmpty && 
                   _filteredDeliveries.every((delivery) => _selectedDeliveryIds.contains(delivery.id));
    });
  }

  void _addSelectedDeliveries() {
    final selectedDeliveries = widget.availableDeliveries
        .where((delivery) => _selectedDeliveryIds.contains(delivery.id))
        .toList();

    if (selectedDeliveries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one delivery'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If tripId is available, add deliveries to trip using bloc
    if (widget.tripId != null) {
      for (final delivery in selectedDeliveries) {
        context.read<DeliveryDataBloc>().add(
          AddDeliveryDataToTripEvent(widget.tripId!),
        );
      }
    }

    // Call the callback with selected deliveries
    widget.onDeliveriesAdded(selectedDeliveries);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedDeliveries.length} deliveries added to trip'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Add Deliveries to Trip',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search deliveries',
                  hintText: 'Search by delivery number, customer, or invoice',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _filterDeliveries();
                  });
                },
              ),
            ),

            // Bulk actions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: _filteredDeliveries.isEmpty ? null : _toggleSelectAll,
                      tristate: false,
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedDeliveryIds.length} selected',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _selectedDeliveryIds.isEmpty ? null : _addSelectedDeliveries,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Deliveries list
            Expanded(
              child: _filteredDeliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No deliveries found matching your search'
                                : 'No available deliveries to add',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredDeliveries.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final delivery = _filteredDeliveries[index];
                        final isSelected = _selectedDeliveryIds.contains(delivery.id);

                        return Card(
                          elevation: isSelected ? 2 : 1,
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (selected) => _toggleDeliverySelection(delivery.id!, selected),
                            ),
                            title: Text(
                              delivery.deliveryNumber ?? 'Unknown Delivery',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (delivery.customer?.name != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text('${delivery.customer!.name}')),
                                    ],
                                  ),
                                if (delivery.customer?.municipality != null || 
                                    delivery.customer?.province != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${delivery.customer!.municipality ?? ''}, ${delivery.customer!.province ?? ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (delivery.invoice?.refId != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text('Invoice: ${delivery.invoice!.refId}')),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onTap: () => _toggleDeliverySelection(delivery.id!, !isSelected),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),

            // Bottom actions
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredDeliveries.length} available deliveries',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedDeliveryIds.isEmpty ? null : _addSelectedDeliveries,
                      icon: const Icon(Icons.add),
                      label: Text('Add ${_selectedDeliveryIds.length} Deliveries'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
