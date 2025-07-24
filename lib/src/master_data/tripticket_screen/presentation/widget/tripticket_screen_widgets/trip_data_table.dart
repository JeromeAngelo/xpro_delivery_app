import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/tripticket_screen_widgets/trip_delete_dialog.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/tripticket_screen_widgets/trip_search_bar.dart';
import 'package:xpro_delivery_admin_app/src/master_data/tripticket_screen/presentation/widget/tripticket_screen_widgets/trip_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:intl/intl.dart';

class TripDataTable extends StatefulWidget {
  final List<TripEntity> trips;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const TripDataTable({
    super.key,
    required this.trips,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  State<TripDataTable> createState() => _TripDataTableState();
}

class _TripDataTableState extends State<TripDataTable> {
  List<int> _selectedRows = [];

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black, // or any color you prefer
    );

    return DataTableLayout(

      title: 'Trip Tickets',
      searchBar: TripSearchBar(
        controller: widget.searchController,
        searchQuery: widget.searchQuery,
        onSearchChanged: widget.onSearchChanged,
      
      ),
      onCreatePressed: () {
        context.go('/tripticket-create');
      },
      createButtonText: 'Create Trip Ticket',
      columns: [
        DataColumn(label: Text('ID', style: headerStyle)),
        DataColumn(label: Text('Trip Number', style: headerStyle)),
        DataColumn(label: Text('Start Date', style: headerStyle)),
        DataColumn(label: Text('End Date', style: headerStyle)),
        DataColumn(label: Text('User', style: headerStyle)),
        DataColumn(label: Text('Status', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows: widget.isLoading ? _buildLoadingRows() : _buildDataRows(),
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPageChanged: widget.onPageChanged,
      isLoading: widget.isLoading,
      enableSelection: true,
      onFiltered: _handleFiltering,
      onRowsSelected: _handleRowsSelected, dataLength: '${widget.trips.length}', onDeleted: () {  },
    );
  }

  List<DataRow> _buildLoadingRows() {
    // Create 10 shimmer loading rows (or however many you want to show during loading)
    return List.generate(
      10,
      (index) => DataRow(
        cells: [
          // ID cell
          DataCell(_buildShimmerCell(60)),
          // Trip Number cell
          DataCell(_buildShimmerCell(100)),
          // Start Date cell
          DataCell(_buildShimmerCell(120)),
          // End Date cell
          DataCell(_buildShimmerCell(120)),
          // User cell
          DataCell(_buildShimmerCell(100)),
          // Status cell
          DataCell(_buildStatusShimmer()),
          // Actions cell
          DataCell(
            Row(
              children: [
                _buildShimmerIcon(),
                const SizedBox(width: 8),
                _buildShimmerIcon(),
                const SizedBox(width: 8),
                _buildShimmerIcon(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCell(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildStatusShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 80,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    return widget.trips.map((trip) {
      // Debug print for each trip
      debugPrint('🔍 TABLE: Processing trip: ${trip.id}');
      debugPrint('🔍 TABLE: User data - Name: ${trip.user?.name}, ID: ${trip.user?.id}');

      return DataRow(
        cells: [
          DataCell(
            Text(trip.id ?? 'N/A'),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            Text(trip.tripNumberId ?? 'N/A'),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            Text(_formatDate(trip.timeAccepted)),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            Text(_formatDate(trip.timeEndTrip)),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            Text(trip.user?.name ?? (trip.user?.id != null ? 'User: ${trip.user!.id}' : 'N/A')),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            TripStatusChip(trip: trip),
            onTap: () => _navigateToTripDetails(context, trip),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Details',
                  onPressed: () => _navigateToTripDetails(context, trip),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                  onPressed: () {
                    // Navigate to edit trip screen
                    if (trip.id != null) {
                      context.go('/tripticket-edit/${trip.id}');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    // We need to check if trip is TripModel before showing delete dialog
                    if (trip is TripModel) {
                      showTripDeleteDialog(context, trip);
                    } else if (trip.id != null) {
                      // Alternative approach if it's not a TripModel
                      context.read<TripBloc>().add(
                        DeleteTripTicketEvent(trip.id!),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Helper method to navigate to trip details
  void _navigateToTripDetails(BuildContext context, TripEntity trip) {
    if (trip.id != null) {
      // First load the trip data
      context.read<TripBloc>().add(GetTripTicketByIdEvent(trip.id!));

      // Then navigate to the specific trip view
      context.go('/tripticket/${trip.id}');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      // Change the format from "MMM dd, yyyy hh:mm a" to "MM/dd/yyyy hh:mm a"
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  // Handle row selection
  void _handleRowsSelected(List<int> selectedIndices) {
    setState(() {
      _selectedRows = selectedIndices;
    });

    // You can perform actions with the selected rows here
    debugPrint('Selected ${_selectedRows.length} rows: $_selectedRows');

    // Example: Get the selected trip entities
    final selectedTrips =
        _selectedRows
            .map(
              (index) =>
                  index < widget.trips.length ? widget.trips[index] : null,
            )
            .where((trip) => trip != null)
            .toList();

    debugPrint('Selected ${selectedTrips.length} trips');
  }

  // Handle filtering action
  void _handleFiltering() {
    // Implement filtering logic here
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Options'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add filter options here
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Trip Number',
                      hintText: 'Filter by trip number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add date range picker
                  Row(
                    children: [
                      const Text('Date Range:'),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          // Show date picker
                        },
                        child: const Text('Select Dates'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Add status filter
                  const Text('Status:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Pending'),
                        selected: false,
                        onSelected: (selected) {
                          // Handle selection
                        },
                      ),
                      FilterChip(
                        label: const Text('In Progress'),
                        selected: false,
                        onSelected: (selected) {
                          // Handle selection
                        },
                      ),
                      FilterChip(
                        label: const Text('Completed'),
                        selected: false,
                        onSelected: (selected) {
                          // Handle selection
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }
}
