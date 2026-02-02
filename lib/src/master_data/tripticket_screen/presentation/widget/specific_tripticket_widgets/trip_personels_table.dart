import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripPersonelsTable extends StatefulWidget {
  final String tripId;
  final VoidCallback? onAddPersonel;

  const TripPersonelsTable({
    super.key,
    required this.tripId,
    this.onAddPersonel,
  });

  @override
  State<TripPersonelsTable> createState() => _TripPersonelsTableState();
}

class _TripPersonelsTableState extends State<TripPersonelsTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        // if (state is TripLoading) {
        //   return _buildLoadingTable();
        // }

        if (state is TripError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading personnel: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TripBloc>().add(
                        GetTripTicketByIdEvent(widget.tripId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        List<PersonelEntity> personels = [];

        if (state is TripTicketLoaded) {
          personels = state.trip.personels;
          debugPrint('✅ Loaded ${personels.length} personnel from trip data');
        }

        // Calculate total pages
        final int totalPages = (personels.length / _itemsPerPage).ceil();
        final int effectiveTotalPages = totalPages == 0 ? 1 : totalPages;

        // Paginate personels
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex =
            startIndex + _itemsPerPage > personels.length
                ? personels.length
                : startIndex + _itemsPerPage;

        final paginatedPersonels =
            startIndex < personels.length
                ? personels.sublist(startIndex, endIndex)
                : [];

        return DataTableLayout(
          title: 'Personnel',
          onCreatePressed: widget.onAddPersonel,
          createButtonText: 'Add Personnel',
          columns: const [
          //  DataColumn(label: Text('ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              paginatedPersonels.map((personel) {
                return DataRow(
                  cells: [
                   // DataCell(Text(personel.id ?? 'N/A')),
                    DataCell(Text(personel.name ?? 'N/A')),
                    DataCell(_buildRoleChip(personel.role)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Edit',
                            onPressed: () {
                              // Edit personnel
                              _showEditPersonelDialog(context, personel);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () {
                              // Delete personnel
                              _showDeleteConfirmationDialog(context, personel);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
          currentPage: _currentPage,
          totalPages: effectiveTotalPages,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          isLoading: state is TripLoading,
          onFiltered: () {},
          dataLength: '${personels.length}',
          onDeleted: () {},
        );
      },
    );
  }

  Widget _buildRoleChip(UserRole? role) {
    if (role == null) return const Text('N/A');

    Color chipColor;
    String roleText;

    switch (role) {
      case UserRole.teamLeader:
        chipColor = Colors.blue;
        roleText = 'Team Leader';
        break;
      case UserRole.driver:
        chipColor = Colors.green;
        roleText = 'Driver';
      case UserRole.helper:
        chipColor = Colors.orange;
        roleText = 'Helper';
        break;
    }

    return Chip(
      label: Text(
        roleText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditPersonelDialog(BuildContext context, PersonelEntity personel) {
    // This would be implemented to show a dialog for editing personnel
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit personnel: ${personel.name}'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    PersonelEntity personel,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${personel.name}?'),
                const SizedBox(height: 10),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Instead of directly deleting the personnel,
                // we would need to update the trip by removing this personnel
                // For now, just show a snackbar indicating the action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Personnel ${personel.name} would be removed from trip',
                    ),
                    action: SnackBarAction(label: 'OK', onPressed: () {}),
                  ),
                );

                // Refresh the trip data after deletion
                context.read<TripBloc>().add(
                  GetTripTicketByIdEvent(widget.tripId),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
