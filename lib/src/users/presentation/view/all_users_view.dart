import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/entity/users_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/all_user_list_widget/all_user_error.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/all_user_list_widget/all_user_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AllUsersView extends StatefulWidget {
  const AllUsersView({super.key});

  @override
  State<AllUsersView> createState() => _DeliveryUsersListViewState();
}

class _DeliveryUsersListViewState extends State<AllUsersView> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load delivery users when the screen initializes
    // Only load if not already loading or loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentState = context.read<GeneralUserBloc>().state;
      debugPrint(
        '📱 AllUsersView initState - Current state: ${currentState.runtimeType}',
      );

      // Trigger loading ONLY for appropriate states
      // DO NOT trigger when UserAuthenticated - this preserves auth state!
      if (currentState is GeneralUserInitial ||
          currentState is GeneralUserError) {
        debugPrint(
          '🔄 Triggering GetAllUsersEvent from initState - State: ${currentState.runtimeType}',
        );
        context.read<GeneralUserBloc>().add(const GetAllUsersEvent());
      } else if (currentState is AllUsersLoaded) {
        debugPrint('✅ Users already loaded, skipping API call');
      } else if (currentState is GeneralUserLoading) {
        debugPrint('⏳ Users currently loading, skipping API call');
      } else if (currentState is UserAuthenticated) {
        debugPrint('✅ User authenticated, triggering GetAllUsersEvent');
        // Still trigger the event, but the state should maintain auth info
        context.read<GeneralUserBloc>().add(const GetAllUsersEvent());
      } else {
        debugPrint(
          '⚠️ Unexpected state in initState: ${currentState.runtimeType}',
        );
        // For unexpected states, show error instead of triggering
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.usersNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/all-users',
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
      child: BlocListener<GeneralUserBloc, GeneralUserState>(
        listener: (context, state) {
          // Listen for authentication errors and handle them appropriately
          if (state is GeneralUserError) {
            debugPrint('⚠️ User management error: ${state.message}');

            // Check if it's an authentication error
            if (state.message.toLowerCase().contains('authentication') ||
                state.message.toLowerCase().contains('unauthorized') ||
                state.message.toLowerCase().contains('not authenticated')) {
              debugPrint(
                '🔒 Authentication error detected, but not auto-logging out',
              );

              // Show a snackbar instead of auto-logout
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Authentication issue: ${state.message}'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      context.read<GeneralUserBloc>().add(
                        const GetAllUsersEvent(),
                      );
                    },
                  ),
                ),
              );
            }
          }
        },
        child: BlocBuilder<GeneralUserBloc, GeneralUserState>(
          builder: (context, state) {
            // Add debug logging to see what state we're receiving
            debugPrint('📱 BlocBuilder: Current state = ${state.runtimeType}');

            // Handle different states
            if (state is GeneralUserInitial) {
              // Show loading indicator without triggering another API call
              // The initState already handles the initial loading
              debugPrint(
                '📱 BlocBuilder: GeneralUserInitial state - showing loading',
              );
              return const Center(child: CircularProgressIndicator());
            }

            // Handle UserAuthenticated state - this might be the "unknown state"
            if (state is UserAuthenticated) {
              debugPrint(
                '📱 BlocBuilder: UserAuthenticated state - showing loading and triggering data load',
              );

              // Show loading while we fetch users
              return SafeArea(
                child: SingleChildScrollView(
                  child: DeliveryUserDataTable(
                    users: [],
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
                  ),
                ),
              );
            }

            if (state is GeneralUserLoading) {
              return 
                SafeArea(
                  child: SingleChildScrollView(
                    child: DeliveryUserDataTable(
                      users: [],
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
                    ),
                  )
               
              );
            }

            if (state is GeneralUserError) {
              return DeliveryUserErrorWidget(errorMessage: state.message);
            }

            if (state is AllUsersLoaded) {
              List<GeneralUserEntity> users = state.users;

              // Filter users based on search query
              if (_searchQuery.isNotEmpty) {
                users =
                    users.where((user) {
                      final query = _searchQuery.toLowerCase();
                      return (user.name?.toLowerCase().contains(query) ??
                              false) ||
                          (user.email?.toLowerCase().contains(query) ?? false);
                    }).toList();
              }

              // Calculate total pages
              _totalPages = (users.length / _itemsPerPage).ceil();
              if (_totalPages == 0) _totalPages = 1;

              // Paginate users
              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex =
                  startIndex + _itemsPerPage > users.length
                      ? users.length
                      : startIndex + _itemsPerPage;

              final List<GeneralUserEntity> paginatedUsers =
                  startIndex < users.length
                      ? List<GeneralUserEntity>.from(
                        users.sublist(startIndex, endIndex),
                      )
                      : <GeneralUserEntity>[];

              return DeliveryUserDataTable(
                users: paginatedUsers,
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
                  // Reset to first page when searching
                  if (_currentPage != 1) {
                    setState(() {
                      _currentPage = 1;
                    });
                  }
                  // Don't trigger API call when search changes - just filter locally
                  debugPrint('🔍 Search query changed to: "$value"');
                },
              );
            }

            // Default fallback - show what state we received for debugging
            debugPrint('❓ BlocBuilder: Unhandled state - ${state.runtimeType}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Unexpected state: ${state.runtimeType}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint(
                        '🔄 Manual retry - triggering GetAllUsersEvent',
                      );
                      context.read<GeneralUserBloc>().add(
                        const GetAllUsersEvent(),
                      );
                    },
                    child: const Text('Retry Loading Users'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
