import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';

class ViewTripsScreen extends StatefulWidget {
  const ViewTripsScreen({super.key});

  @override
  State<ViewTripsScreen> createState() => _ViewTripsScreenState();
}

class _ViewTripsScreenState extends State<ViewTripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search trip number...',
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _triggerSearch('');
                  },
                ),
              ],
              onChanged: _triggerSearch,
            ),
          ),
          Expanded(
            child: BlocBuilder<TripBloc, TripState>(
              builder: (context, state) {
                if (state is TripSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TripsSearchResults) {
                  return _buildSearchResults(state.trips);
                }

                if (state is TripDateRangeResults) {
                  return _buildSearchResults(state.trips);
                }

                if (state is TripError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }

                return const Center(
                  child: Text('Search for trips'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSearch(String query) {
    context.read<TripBloc>().add(
          SearchTripsAdvancedEvent(
            tripNumberId: query.isNotEmpty ? query : null,
            startDate: _selectedStartDate,
            endDate: _selectedEndDate,
          ),
        );
  }

  Widget _buildSearchResults(List<TripEntity> trips) {
    if (trips.isEmpty) {
      return const Center(
        child: Text('No trips found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Icon(
              trip.isAccepted == true ? Icons.check_circle : Icons.pending,
              color: trip.isAccepted == true
                  ? Theme.of(context).colorScheme.primary
                  : Colors.orange,
            ),
            title: Text(
              'Trip #${trip.tripNumberId ?? 'N/A'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created: ${_formatDate(trip.created)}'),
                if (trip.timeAccepted != null)
                  Text('Accepted: ${_formatDate(trip.timeAccepted)}'),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              // Handle trip selection
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_selectedStartDate != null
                  ? _formatDate(_selectedStartDate)
                  : 'Not set'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedStartDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_selectedEndDate != null
                  ? _formatDate(_selectedEndDate)
                  : 'Not set'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedEndDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedEndDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStartDate = null;
                _selectedEndDate = null;
              });
              Navigator.pop(context);
              _triggerSearch(_searchController.text);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _triggerSearch(_searchController.text);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
