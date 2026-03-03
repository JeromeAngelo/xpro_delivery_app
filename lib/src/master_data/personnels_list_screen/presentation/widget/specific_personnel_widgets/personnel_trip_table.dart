import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class PersonnelTripTable extends StatefulWidget {
  final List<PersonnelTripEntity> personnelTrips;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final bool showError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PersonnelTripTable({
    super.key,
    required this.personnelTrips,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    this.showError = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<PersonnelTripTable> createState() => _PersonnelTripTableState();
}

class _PersonnelTripTableState extends State<PersonnelTripTable> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return DataTableLayout(
      title: 'Personnel Trip History',
      searchBar: _buildSearchBar(),
      columns: [
        DataColumn(label: Text('Trip Number', style: headerStyle)),
        DataColumn(label: Text('Trip Status', style: headerStyle)),
        DataColumn(label: Text('Start Date', style: headerStyle)),
        DataColumn(label: Text('End Date', style: headerStyle)),
        DataColumn(label: Text('Total Assigned Trips', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows: widget.isLoading ? _buildLoadingRows() : _buildDataRows(),
      currentPage: widget.currentPage,
      totalPages: widget.totalPages,
      onPageChanged: widget.onPageChanged,
      isLoading: widget.isLoading,
      enableSelection: false,
      dataLength: widget.showError ? '0' : '${widget.personnelTrips.length}',
      onDeleted: () {},
      onRowsSelected: (selectedIndices) {},
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by trip number...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }

  List<DataRow> _buildLoadingRows() {
    return List.generate(
      5,
      (index) => DataRow(
        cells: [
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(80)),
          DataCell(
            Row(
              children: [
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

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    // Show error message if there's an error
    if (widget.showError) {
      return [
        DataRow(
          cells: [
            DataCell(
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      widget.errorMessage ?? 'Error loading trip data',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(width: 16),
                    if (widget.onRetry != null)
                      TextButton(
                        onPressed: widget.onRetry,
                        child: Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
          ],
        ),
      ];
    }
    
    // Show empty message if no data
    if (widget.personnelTrips.isEmpty) {
      return [
        DataRow(
          cells: [
            DataCell(
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No trip assignments found for this personnel',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
          ],
        ),
      ];
    }

    return widget.personnelTrips.map((personnelTrip) {
      // For each personnel trip, we show each assigned trip as a separate row
      if (personnelTrip.assignedTrip.isEmpty) {
        return DataRow(
          cells: [
            DataCell(Text('No trips assigned')),
            DataCell(Text('N/A')),
            DataCell(Text('N/A')),
            DataCell(Text('N/A')),
            DataCell(Text('0')),
            DataCell(Container()),
          ],
        );
      }

      // Show the first trip, and indicate total count
      final firstTrip = personnelTrip.assignedTrip.first;
      
      return DataRow(
        cells: [
          DataCell(
            Text(firstTrip.tripNumberId ?? 'N/A'),
            onTap: () => _navigateToTripDetails(context, firstTrip.id),
          ),
          DataCell(
            _buildStatusChip(firstTrip),
            onTap: () => _navigateToTripDetails(context, firstTrip.id),
          ),
          DataCell(
            Text(_formatDate(firstTrip.timeAccepted)),
            onTap: () => _navigateToTripDetails(context, firstTrip.id),
          ),
          DataCell(
            Text(_formatDate(firstTrip.timeEndTrip)),
            onTap: () => _navigateToTripDetails(context, firstTrip.id),
          ),
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${personnelTrip.assignedTrip.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Trip Details',
                  onPressed: () => _navigateToTripDetails(context, firstTrip.id),
                ),
                if (personnelTrip.assignedTrip.length > 1)
                  IconButton(
                    icon: Icon(Icons.list, color: Colors.green),
                    tooltip: 'View All Trips (${personnelTrip.assignedTrip.length})',
                    onPressed: () => _showAllTripsDialog(context, personnelTrip),
                  ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildStatusChip(trip) {
    String status = 'Unknown';
    Color color = Colors.grey;

    if (trip.isAccepted == true && trip.isEndTrip == true) {
      status = 'Completed';
      color = Colors.green;
    } else if (trip.isAccepted == true && trip.isEndTrip != true) {
      status = 'In Progress';
      color = Colors.orange;
    } else {
      status = 'Pending';
      color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  void _navigateToTripDetails(BuildContext context, String? tripId) {
    if (tripId != null && tripId.isNotEmpty) {
      context.go('/tripticket/$tripId');
    }
  }

  void _showAllTripsDialog(BuildContext context, PersonnelTripEntity personnelTrip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Assigned Trips (${personnelTrip.assignedTrip.length})'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: personnelTrip.assignedTrip.length,
            itemBuilder: (context, index) {
              final trip = personnelTrip.assignedTrip[index];
              return ListTile(
                leading: Icon(Icons.local_shipping),
                title: Text(trip.tripNumberId ?? 'N/A'),
                subtitle: Text(
                  'Start: ${_formatDate(trip.timeAccepted)} | End: ${_formatDate(trip.timeEndTrip)}',
                ),
                trailing: _buildStatusChip(trip),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToTripDetails(context, trip.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
