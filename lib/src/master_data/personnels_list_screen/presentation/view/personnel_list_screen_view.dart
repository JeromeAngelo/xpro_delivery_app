import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/personnel_list_widget/personnel_data_table.dart';
import 'package:xpro_delivery_admin_app/src/master_data/personnels_list_screen/presentation/widget/personnel_list_widget/personnel_widget_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PersonnelListScreenView extends StatefulWidget {
  const PersonnelListScreenView({super.key});

  @override
  State<PersonnelListScreenView> createState() =>
      _PersonnelListScreenViewState();
}

class _PersonnelListScreenViewState extends State<PersonnelListScreenView> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25; // Same as tripticket_screen_view.dart
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load personnel when the screen initializes
    context.read<PersonelBloc>().add(GetPersonelEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute:
          '/personnel-list', // Match the route in app_navigation_items.dart
      onNavigate: (route) {
        // Handle navigation using GoRouter
        context.go(route);
      },
      onThemeToggle: () {
        // Handle theme toggle
      },
      onNotificationTap: () {
        // Handle notification tap
      },
      onProfileTap: () {
        // Handle profile tap
      },
      child: BlocBuilder<PersonelBloc, PersonelState>(
        builder: (context, state) {
          // Handle different states
          if (state is PersonelInitial) {
            // Initial state, trigger loading
            context.read<PersonelBloc>().add(GetPersonelEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PersonelLoading) {
            return PersonnelDataTable(
              personnel: [],
              isLoading: true,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            );
          }

          if (state is PersonelError) {
            return PersonnelErrorWidget(errorMessage: state.message);
          }

          if (state is PersonelLoaded) {
            List<PersonelEntity> personnel = state.personel;

            // Filter personnel based on search query
            if (_searchQuery.isNotEmpty) {
              personnel =
                  personnel.where((person) {
                    final query = _searchQuery.toLowerCase();
                    return (person.name?.toLowerCase().contains(query) ??
                            false) ||
                        (person.role?.toString().toLowerCase().contains(
                              query,
                            ) ??
                            false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (personnel.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate personnel
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > personnel.length
                    ? personnel.length
                    : startIndex + _itemsPerPage;

            final paginatedPersonnel =
                startIndex < personnel.length
                    ? personnel.sublist(startIndex, endIndex)
                    : <PersonelEntity>[];

            return PersonnelDataTable(
              personnel: paginatedPersonnel,
              isLoading: false,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // If search query is empty, refresh the personnel list
                if (value.isEmpty) {
                  context.read<PersonelBloc>().add(GetPersonelEvent());
                }
              },
            );
          }

          // Default fallback
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
