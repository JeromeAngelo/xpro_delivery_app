import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/domain/entity/invoice_preset_group_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/invoice_preset_group/presentation/bloc/invoice_preset_group_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/invoice_preset_groups_screen/presentation/widgets/invoice_preset_group_table.dart';

class InvoicePresetGroupScreen extends StatefulWidget {
  const InvoicePresetGroupScreen({super.key});

  @override
  State<InvoicePresetGroupScreen> createState() =>
      _InvoicePresetGroupScreenState();
}

class _InvoicePresetGroupScreenState extends State<InvoicePresetGroupScreen> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25; // 25 items per page
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load invoice preset groups when the screen initializes
    context.read<InvoicePresetGroupBloc>().add(
      const GetAllInvoicePresetGroupsEvent(),
    );
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
      currentRoute: '/invoice-preset-groups', // Match the route in router.dart
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
      child: BlocBuilder<InvoicePresetGroupBloc, InvoicePresetGroupState>(
        builder: (context, state) {
          // Handle different states
          if (state is InvoicePresetGroupInitial) {
            // Initial state, trigger loading
            context.read<InvoicePresetGroupBloc>().add(
              const GetAllInvoicePresetGroupsEvent(),
            );
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoicePresetGroupLoading) {
            return InvoicePresetGroupTable(
              presetGroups: const [],
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
                // If search query is not empty, search for preset groups
                if(value.isNotEmpty) {
                  // If search query is empty, load all preset groups
                  context.read<InvoicePresetGroupBloc>().add(
                    const GetAllInvoicePresetGroupsEvent(),
                  );
                }
              },
            );
          }

          if (state is InvoicePresetGroupError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<InvoicePresetGroupBloc>().add(
                        const GetAllInvoicePresetGroupsEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AllInvoicePresetGroupsLoaded) {
            List<InvoicePresetGroupEntity> presetGroups = state.presetGroups;

            // Filter preset groups based on search query if not already filtered by the bloc
            if (_searchQuery.isNotEmpty &&
                state is! PresetGroupsSearchResults) {
              presetGroups =
                  presetGroups.where((group) {
                    final query = _searchQuery.toLowerCase();
                    return (group.id?.toLowerCase().contains(query) ?? false) ||
                        (group.refId?.toLowerCase().contains(query) ?? false) ||
                        (group.name?.toLowerCase().contains(query) ?? false);
                  }).toList();
            }

            // Calculate total pages
            _totalPages = (presetGroups.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate preset groups
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > presetGroups.length
                    ? presetGroups.length
                    : startIndex + _itemsPerPage;

            final List<InvoicePresetGroupEntity> paginatedPresetGroups =
                startIndex < presetGroups.length
                    ? presetGroups.sublist(startIndex, endIndex)
                    : [];

            return InvoicePresetGroupTable(
              presetGroups: paginatedPresetGroups,
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
                  _currentPage = 1; // Reset to first page when searching
                });
                if(value.isNotEmpty) {
                  // If search query is empty, load all preset groups
                  context.read<InvoicePresetGroupBloc>().add(
                    const GetAllInvoicePresetGroupsEvent(),
                  );
                }
              },
              errorMessage: null,
              onRetry: () {
                context.read<InvoicePresetGroupBloc>().add(
                  const GetAllInvoicePresetGroupsEvent(),
                );
              },
            );
          }

          // Handle search results state
          if (state is PresetGroupsSearchResults) {
            List<InvoicePresetGroupEntity> presetGroups = state.presetGroups;

            // Calculate total pages
            _totalPages = (presetGroups.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // Paginate preset groups
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex =
                startIndex + _itemsPerPage > presetGroups.length
                    ? presetGroups.length
                    : startIndex + _itemsPerPage;

            final List<InvoicePresetGroupEntity> paginatedPresetGroups =
                startIndex < presetGroups.length
                    ? presetGroups.sublist(startIndex, endIndex)
                    : [];

            return InvoicePresetGroupTable(
              presetGroups: paginatedPresetGroups,
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
                  _currentPage = 1; // Reset to first page when searching
                });
                // If search query is not empty, search for preset groups
                 if(value.isNotEmpty) {
                  // If search query is empty, load all preset groups
                  context.read<InvoicePresetGroupBloc>().add(
                    const GetAllInvoicePresetGroupsEvent(),
                  );
                }
              },
              errorMessage: null,
              onRetry: () {
                if (_searchQuery.isNotEmpty) {
                  context.read<InvoicePresetGroupBloc>().add(
                    SearchPresetGroupByRefIdEvent(_searchQuery),
                  );
                } else {
                  context.read<InvoicePresetGroupBloc>().add(
                    const GetAllInvoicePresetGroupsEvent(),
                  );
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
