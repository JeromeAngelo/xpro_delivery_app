import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_trip_collection/domain/entity/user_trip_collection_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';

class UserTripCollectionTable extends StatefulWidget {
  final List<UserTripCollectionEntity> tripCollections;
  final bool isLoading;
  final String userId;
  final VoidCallback? onRefresh;

  const UserTripCollectionTable({
    super.key,
    required this.tripCollections,
    required this.userId,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<UserTripCollectionTable> createState() =>
      _UserTripCollectionTableState();
}

class _UserTripCollectionTableState extends State<UserTripCollectionTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Search filter
    List<UserTripCollectionEntity> filtered = widget.tripCollections;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          widget.tripCollections.where((collection) {
            final tripFields =
                collection.trips
                    .map(
                      (t) =>
                          '${t.id} ${t.tripNumberId} ${t.name} ${t.vehicle?.name}',
                    )
                    .join(' ')
                    .toLowerCase();

            return tripFields.contains(q) ||
                (collection.id?.toLowerCase().contains(q) ?? false);
          }).toList();
    }

    // Pagination
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end =
        (start + _itemsPerPage > filtered.length)
            ? filtered.length
            : start + _itemsPerPage;

    final pageItems =
        start < filtered.length ? filtered.sublist(start, end) : [];

    return DataTableLayout(
      title: 'Trip History',
      searchBar: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Trip...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged:
            (value) => setState(() {
              _searchQuery = value;
              _currentPage = 1;
            }),
      ),
      onCreatePressed: null,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Trip Number')),
        DataColumn(label: Text('Trip Name')),
        DataColumn(label: Text('Start Date')),
        DataColumn(label: Text('End Date')),

        DataColumn(label: Text('Actions')),
      ],
      rows:
          pageItems.map((collection) {
            final hasTrips = collection.trips.isNotEmpty;
            final firstTrip = hasTrips ? collection.trips.first : null;

            return DataRow(
              cells: [
                DataCell(Text(collection.id?.substring(0, 8) ?? 'N/A')),
                DataCell(Text(firstTrip?.tripNumberId ?? 'N/A')),
                DataCell(Text(firstTrip?.name ?? 'N/A')),
                DataCell(Text(_formatDate(firstTrip?.timeAccepted))),
                DataCell(Text(_formatDate(firstTrip?.timeEndTrip))),

                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed:
                        () => _showTripDetailsDialog(context, collection),
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: _currentPage,
      totalPages: totalPages > 0 ? totalPages : 1,
      onPageChanged: (page) => setState(() => _currentPage = page),
      isLoading: widget.isLoading,
      onFiltered: () {},
      onDeleted: () {},
      dataLength: filtered.length.toString(),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  void _showTripDetailsDialog(
    BuildContext context,
    UserTripCollectionEntity collection,
  ) {
    if (collection.trips.first.id != null) {
      // First load the trip data

      // Then navigate to the specific trip view
      context.go('/tripticket/${collection.trips.first.id}');
    }
  }
}
