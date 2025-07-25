import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/presentation/bloc/personnel_trip_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/specific_personnel_widgets/specific_personnel_dashboard.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/specific_personnel_widgets/personnel_trip_table.dart';

class SpecificPersonnelScreenView extends StatefulWidget {
  final String personnelId;

  const SpecificPersonnelScreenView({
    super.key,
    required this.personnelId,
  });

  @override
  State<SpecificPersonnelScreenView> createState() => _SpecificPersonnelScreenViewState();
}

class _SpecificPersonnelScreenViewState extends State<SpecificPersonnelScreenView> {
  PersonelEntity? _currentPersonnel;
  List<PersonnelTripEntity> _personnelTrips = [];
  
  // Pagination for personnel trips
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPersonnelData();
  }

  void _loadPersonnelData() {
    // Load personnel details by ID
    context.read<PersonelBloc>().add(GetPersonelByIdEvent(widget.personnelId));
    
    // Load personnel trips
    context.read<PersonnelTripBloc>().add(
      GetPersonnelTripsByPersonnelIdEvent(widget.personnelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/personnel-list',
      onNavigate: (route) {
        context.go(route);
      },
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      disableScrolling: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => context.go('/personnel-list'),
                  tooltip: 'Back to Personnel List',
                ),
                const SizedBox(width: 8),
                Text(
                  'Personnel Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Personnel Dashboard
                  BlocBuilder<PersonelBloc, PersonelState>(
                    builder: (context, state) {
                      if (state is PersonelLoadedById) {
                        _currentPersonnel = state.personel;
                      }
                      
                      if (state is PersonelError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text('Error loading personnel data'),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadPersonnelData,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        constraints: BoxConstraints(minHeight: 200),
                        child: SpecificPersonnelDashboard(
                          personnel: _currentPersonnel ?? PersonelEntity.empty(),
                          isLoading: state is PersonelLoading,
                          onEdit: () {
                            _showEditDialog();
                          },
                          onDelete: () {
                            _showDeleteDialog();
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Personnel Trip Table
                  Container(
                    height: 600, // Fixed height to prevent overflow
                    child: BlocBuilder<PersonnelTripBloc, PersonnelTripState>(
                      builder: (context, state) {
                        bool isLoading = state is PersonnelTripLoading;
                        List<PersonnelTripEntity> personnelTrips = [];

                        if (state is PersonnelTripsByPersonnelIdLoaded) {
                          personnelTrips = state.personnelTrips;
                          _personnelTrips = personnelTrips;
                        } else if (state is PersonnelTripError) {
                          // Keep empty list for error state - table will handle it
                          personnelTrips = [];
                        }

                        // Apply search filter
                        List<PersonnelTripEntity> filteredTrips = personnelTrips;
                        if (_searchQuery.isNotEmpty) {
                          filteredTrips = personnelTrips.where((pt) {
                            return pt.assignedTrip.any((trip) =>
                              trip.tripNumberId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
                            );
                          }).toList();
                        }

                        // Calculate pagination
                        _totalPages = (filteredTrips.length / _itemsPerPage).ceil();
                        if (_totalPages == 0) _totalPages = 1;

                        final startIndex = (_currentPage - 1) * _itemsPerPage;
                        final endIndex = startIndex + _itemsPerPage > filteredTrips.length
                            ? filteredTrips.length
                            : startIndex + _itemsPerPage;

                        final paginatedTrips = startIndex < filteredTrips.length
                            ? filteredTrips.sublist(startIndex, endIndex)
                            : <PersonnelTripEntity>[];

                        return PersonnelTripTable(
                          personnelTrips: paginatedTrips,
                          isLoading: isLoading,
                          currentPage: _currentPage,
                          totalPages: _totalPages,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          searchQuery: _searchQuery,
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _currentPage = 1; // Reset to first page when searching
                            });
                          },
                          showError: state is PersonnelTripError,
                          errorMessage: state is PersonnelTripError ? 'Error loading trip data' : null,
                          onRetry: state is PersonnelTripError ? () {
                            context.read<PersonnelTripBloc>().add(
                              GetPersonnelTripsByPersonnelIdEvent(widget.personnelId),
                            );
                          } : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Personnel'),
        content: Text('Edit functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement edit functionality
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Personnel'),
        content: Text(
          'Are you sure you want to delete this personnel? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PersonelBloc>().add(
                DeletePersonelEvent(widget.personnelId),
              );
              context.go('/personnel-list');
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
