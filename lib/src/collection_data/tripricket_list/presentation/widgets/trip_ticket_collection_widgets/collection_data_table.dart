import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/collection_data/tripricket_list/presentation/widgets/trip_ticket_collection_widgets/collection_searchbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CollectionDataTable extends StatelessWidget {
  final List<TripEntity> trips;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const CollectionDataTable({
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
  Widget build(BuildContext context) {
    return DataTableLayout(
      title: 'Trip Tickets for Collection',
      searchBar: CollectionSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: null, // No create button for collections view
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Trip Number')),
        DataColumn(label: Text('Start Date')),
        DataColumn(label: Text('End Date')),
     //   DataColumn(label: Text('Payment Modes')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows:
          trips.map((trip) {
            return DataRow(
              cells: [
                DataCell(
                  Text(trip.id ?? 'N/A'),
                  onTap: () => _navigateToTripData(context, trip),
                ),
                DataCell(
                  Text(trip.tripNumberId ?? 'N/A'),
                  onTap: () => _navigateToTripData(context, trip),
                ),
                DataCell(
                  Text(_formatDate(trip.timeAccepted)),
                  onTap: () => _navigateToTripData(context, trip),
                ),
                DataCell(
                  Text(_formatDate(trip.timeEndTrip)),
                  onTap: () => _navigateToTripData(context, trip),
                ),
                // DataCell(
                //   _buildPaymentModesCell(trip),
                //   onTap: () => _navigateToTripData(context, trip),
                // ),
                DataCell(
                  _buildStatusChip(trip),
                  onTap: () => _navigateToTripData(context, trip),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Collections',
                        onPressed: () => _navigateToTripData(context, trip),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,
      dataLength: '${trips.length}', onDeleted: () {  },
    );
  }

  void _navigateToTripData(BuildContext context, TripEntity trip) {
    if (trip.id != null) {
      context.read<TripBloc>().add(GetTripTicketByIdEvent(trip.id!));
      context.go('/collections/${trip.id}');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildStatusChip(TripEntity trip) {
    Color color;
    String status;

    if (trip.isEndTrip == true) {
      color = Colors.green;
      status = 'Completed';
    } else if (trip.isAccepted == true) {
      color = Colors.blue;
      status = 'In Progress';
    } else {
      color = Colors.orange;
      status = 'Pending';
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

}
