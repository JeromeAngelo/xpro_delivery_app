import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';

import '../../../../core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart'
    show TripBloc;
import '../../../../core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import '../../../../core/common/app/features/vehicle/vehicle_profile/domain/entity/vehicle_profile_entity.dart';
import '../../../../core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_bloc.dart';
import '../../../../core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_event.dart';
import '../../../../core/common/app/features/vehicle/vehicle_profile/presentation/bloc/vehicle_profile_state.dart';

class VehicleAssignedTripsTable extends StatelessWidget {
  final String vehicleId;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const VehicleAssignedTripsTable({
    super.key,
    required this.vehicleId,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleProfileBloc, VehicleProfileState>(
      builder: (context, state) {
        VehicleProfileEntity? profile;
        bool loading = false;
        String? errorMessage;

        if (state is VehicleProfileLoading) {
          loading = true;
          debugPrint('🔄 [TABLE] Loading vehicle profile...');
        } else if (state is VehicleProfileByIdLoaded) {
          // Check if the loaded profile matches the delivery vehicle ID
          final matchesById =
              state.vehicleProfile.deliveryVehicleData?.id == vehicleId;
          final matchesByData =
              state.vehicleProfile.deliveryVehicleData?.id == vehicleId;

          debugPrint('📊 [TABLE] Profile loaded - Checking IDs:');
          debugPrint('   Expected vehicleId: $vehicleId');
          debugPrint('   Profile ID: ${state.vehicleProfile.id}');
          //debugPrint('   Delivery Vehicle ID: ${state.vehicleProfile.deliveryVehicleId}');
          debugPrint(
            '   Delivery Vehicle Data ID: ${state.vehicleProfile.deliveryVehicleData?.id}',
          );
          debugPrint('   Matches by deliveryVehicleId: $matchesById');
          debugPrint('   Matches by deliveryVehicleData.id: $matchesByData');

          if (matchesById || matchesByData) {
            profile = state.vehicleProfile;
            loading = false;
            debugPrint(
              '✅ [TABLE] Profile matched! Trips count: ${profile.assignedTrips?.length ?? 0}',
            );
          } else {
            debugPrint(
              '⚠️ [TABLE] Profile loaded but IDs don\'t match - ignoring this profile',
            );
          }
        } else if (state is VehicleProfileError) {
          loading = false;
          errorMessage = state.message;
          debugPrint('❌ [TABLE] Error loading profile: $errorMessage');
        }

        final assignedTrips = profile?.assignedTrips ?? [];
        debugPrint('📋 [TABLE] Rendering with ${assignedTrips.length} trips');

        // Search filtering
        final filteredTrips =
            assignedTrips.where((trip) {
              final q = searchQuery.toLowerCase();
              final tripNo = trip.tripNumberId?.toLowerCase() ?? "";
              final personnels =
                  trip.personels
                      .map((p) => p.name?.toLowerCase())
                      .join(", ")
                      .toLowerCase();

              return tripNo.contains(q) || personnels.contains(q);
            }).toList();

        return DataTableLayout(
          title: 'Assigned Trips',
          searchBar: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by Trip Number or Personnels...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: onSearchChanged,
          ),

          // No create button for this table
          onCreatePressed: null,
          createButtonText: '',

          columns: const [
            DataColumn(label: Text('Trip Number')),
            DataColumn(label: Text('Route Name')),

            DataColumn(label: Text('Personnels')),
            DataColumn(label: Text('Dispatched Date')),
            DataColumn(label: Text('End Trip Date')),
            DataColumn(label: Text('Actions')),
          ],

          rows:
              filteredTrips.map((trip) {
                return DataRow(
                  cells: [
                    // Trip Number
                    DataCell(Text(trip.tripNumberId ?? 'N/A')),
                    DataCell(Text(trip.name ?? 'N/A')),

                    // Personnels (List)
                    DataCell(
                      Text(
                        trip.personels.isEmpty
                            ? 'No Personnels'
                            : trip.personels
                                .map((p) => p.name ?? 'N/A')
                                .join(', '),
                      ),
                    ),

                    // Dispatched Date
                    DataCell(Text(_fmtDate(trip.timeAccepted))),

                    // End Trip Date
                    DataCell(Text(_fmtDate(trip.timeEndTrip))),

                    // Actions
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Trip Details',
                        onPressed: () {
                          if (trip.id != null) {
                            // First load the trip data
                            context.read<TripBloc>().add(
                              GetTripTicketByIdEvent(trip.id!),
                            );

                            // Then navigate to the specific trip view
                            context.go('/tripticket/${trip.id}');
                          }
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),

          currentPage: currentPage,
          totalPages: totalPages,
          onPageChanged: onPageChanged,

          isLoading: loading,
          errorMessage: errorMessage,
          onRetry:
              errorMessage != null
                  ? () => context.read<VehicleProfileBloc>().add(
                    GetVehicleProfileByIdEvent(vehicleId),
                  )
                  : null,

          onFiltered: null,
          dataLength: '${filteredTrips.length}',
          onDeleted: () {},
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _fmtDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MM/dd/yyyy hh:mm a').format(date);
  }
}
