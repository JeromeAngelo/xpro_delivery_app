import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import 'filter_delivery_widget.dart';

class SearchBarWidget extends StatefulWidget {
  final List<DeliveryDataEntity> allDeliveries;
  final Function(List<DeliveryDataEntity>) onSearchResults;
  final Function(String?) onStatusFilterChanged;

  const SearchBarWidget({
    super.key,
    required this.allDeliveries,
    required this.onSearchResults,
    required this.onStatusFilterChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    final filteredResults =
        widget.allDeliveries.where((delivery) {
          final storeName = (delivery.storeName ?? '').toLowerCase();
          final barangay = (delivery.barangay ?? '').toLowerCase();
          final municipality = (delivery.municipality ?? '').toLowerCase();

          // Get latest delivery update for status checking
          final latestUpdate = _getLatestDeliveryUpdate(delivery);

          // Check text search (store, barangay, municipality)
          final textMatches =
              query.isEmpty ||
              storeName.contains(query) ||
              barangay.contains(query) ||
              municipality.contains(query);

          // Check status filter (if selected, match against latest update title)
          final statusMatches =
              _selectedStatus == null ||
              (latestUpdate.title ?? '').toLowerCase() ==
                  _selectedStatus!.toLowerCase();

          return textMatches && statusMatches;
        }).toList();

    widget.onSearchResults(filteredResults);
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    _selectedStatus = null;
    widget.onStatusFilterChanged(null);
    widget.onSearchResults(widget.allDeliveries);
  }

  void _showStatusFilterDialog() async {
    // Status choices - excluding PENDING
    const statusOptions = [
      'Arrived',
      'Waiting for customer',
      'Invoices in queue',
      'Unloading',
      'Mark as undelivered',
      'In transit',
      'Mark as received',
      'End delivery',
    ];

    await FilterDialogWidget.showStatusFilterDialog(
      context: context,
      selectedStatus: _selectedStatus,
      statusOptions: statusOptions,
      onStatusSelected: (status) {
        setState(() {
          _selectedStatus = status;
        });
        widget.onStatusFilterChanged(status);
        _onSearchChanged();
        _focusNode.unfocus();
      },
    );
    // If user canceled (returned null), do nothing
  }

  // Get the latest delivery update based on timestamp
  dynamic _getLatestDeliveryUpdate(DeliveryDataEntity delivery) {
    final deliveryUpdates = delivery.deliveryUpdates.toList();
    if (deliveryUpdates.isEmpty) {
      return _EmptyDeliveryUpdate();
    }

    DateTime? tsFor(dynamic u) {
      try {
        final dyn = u as dynamic;
        return dyn.lastLocalUpdatedAt ?? dyn.updated ?? dyn.time;
      } catch (_) {
        try {
          return (u as dynamic).updated ?? (u as dynamic).time;
        } catch (_) {
          return null;
        }
      }
    }

    deliveryUpdates.sort((a, b) {
      final at = tsFor(a);
      final bt = tsFor(b);
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return at.compareTo(bt);
    });

    return deliveryUpdates.last;
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _searchController.text.isNotEmpty;
    final hasFilter = _selectedStatus != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search store or invoice...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter icon (always visible on the right side)
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      hasFilter
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                ),
                onPressed: _showStatusFilterDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Clear search icon
              if (hasText)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: _clearSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          // Real-time search as user types
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// Helper class for empty delivery update
class _EmptyDeliveryUpdate {
  String? title;
}