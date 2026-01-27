import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'trip_status_chip.dart';

class RecentTripsWidget extends StatelessWidget {
  final List<TripEntity> trips;
  final bool isLoading;

  const RecentTripsWidget({
    super.key,
    required this.trips,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort trips by created date (newest first)
    final sortedTrips = List<TripEntity>.from(trips)..sort(
      (a, b) =>
          (b.created ?? DateTime.now()).compareTo(a.created ?? DateTime.now()),
    );

    // Take only the 5 most recent trips
    final recentTrips = sortedTrips.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Trips',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/tripticket'),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
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
            else if (recentTrips.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent trips found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5), // Trip Number
                  1: FlexColumnWidth(2), // Start Date
                  2: FlexColumnWidth(2), // End Date
                  3: FlexColumnWidth(2), // User
                  4: FlexColumnWidth(1.5), // Status
                  5: FlexColumnWidth(1), // Actions
                },
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                children: [
                  // Table Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: [
                      _buildTableHeader(context, 'Trip Number'),
                      _buildTableHeader(context, 'Start Date'),
                      _buildTableHeader(context, 'End Date'),
                      _buildTableHeader(context, 'User'),
                      _buildTableHeader(context, 'Status'),
                      _buildTableHeader(context, 'Actions'),
                    ],
                  ),
                  // Table Rows
                  ...recentTrips.map(
                    (trip) => TableRow(
                      children: [
                        _buildTableCell(context, trip.tripNumberId ?? 'N/A'),
                        _buildTableCell(
                          context,
                          _formatDate(trip.timeAccepted),
                        ),
                        _buildTableCell(context, _formatDate(trip.timeEndTrip)),
                        _buildTableCell(context, trip.user?.name ?? 'N/A'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: TripStatusChip(trip: trip),
                        ),
                        _buildActionCell(context, trip),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTableCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(text),
    );
  }

  Widget _buildActionCell(BuildContext context, TripEntity trip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: IconButton(
        icon: const Icon(Icons.visibility, color: Colors.blue),
        onPressed: () {
          if (trip.id != null) {
            context.go('/tripticket/${trip.id}');
          }
        },
        tooltip: 'View Details',
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}