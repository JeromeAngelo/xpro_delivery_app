import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class SearchBarWidget extends StatefulWidget {
  final List<DeliveryDataEntity> allDeliveries;
  final Function(List<DeliveryDataEntity>) onSearchResults;

  const SearchBarWidget({
    super.key,
    required this.allDeliveries,
    required this.onSearchResults,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      widget.onSearchResults(widget.allDeliveries);
      return;
    }

    final filteredResults =
        widget.allDeliveries.where((delivery) {
          final storeName = (delivery.storeName ?? '').toLowerCase();
          final barangay = (delivery.barangay ?? '').toLowerCase();
          final municipality = (delivery.municipality ?? '').toLowerCase();

          return storeName.contains(query) ||
              barangay.contains(query) ||
              municipality.contains(query);
        }).toList();

    widget.onSearchResults(filteredResults);
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
    widget.onSearchResults(widget.allDeliveries);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _searchController.text.isNotEmpty;

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
          suffixIcon:
              hasText
                  ? IconButton(
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
                  )
                  : null,
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
