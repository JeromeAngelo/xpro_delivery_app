import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';

import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';

import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/specific_user_widgets/user_details_dashboard.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/specific_user_widgets/user_trip_collection_table.dart';

import '../../../../core/common/app/features/users_trip_collection/presentation/bloc/users_trip_collection_bloc.dart';
import '../../../../core/common/app/features/users_trip_collection/presentation/bloc/users_trip_collection_event.dart';
import '../../../../core/common/app/features/users_trip_collection/presentation/bloc/users_trip_collection_state.dart';

class SpecificUserView extends StatefulWidget {
  final String userId;

  const SpecificUserView({super.key, required this.userId});

  @override
  State<SpecificUserView> createState() => _SpecificUserViewState();
}

class _SpecificUserViewState extends State<SpecificUserView> {
  // local state
  bool _isUserLoading = true;
  bool _isTripsLoading = true;
  String? _userErrorMessage;
  String? _tripsErrorMessage;

  @override
  void initState() {
    super.initState();

    // Load user data and user's trip collections
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneralUserBloc>().add(GetUserByIdEvent(widget.userId));
      context.read<UsersTripCollectionBloc>().add(GetUserTripCollectionsEvent(widget.userId));
    });
  }

  Future<void> _manualRefresh() async {
    setState(() {
      _isUserLoading = true;
      _isTripsLoading = true;
      _userErrorMessage = null;
      _tripsErrorMessage = null;
    });

    context.read<GeneralUserBloc>().add(GetUserByIdEvent(widget.userId));
    context.read<UsersTripCollectionBloc>().add(GetUserTripCollectionsEvent(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.usersNavigationItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/all-users',
      onNavigate: (route) => context.go(route),
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      title: 'User Details',
      child: MultiBlocListener(
        listeners: [
          BlocListener<GeneralUserBloc, GeneralUserState>(
            listener: (context, state) {
              if (state is GeneralUserLoading) {
                setState(() {
                  _isUserLoading = true;
                });
              } else if (state is UserByIdLoaded) {
                setState(() {
                  _isUserLoading = false;
                  _userErrorMessage = null;
                });
              } else if (state is GeneralUserError) {
                setState(() {
                  _isUserLoading = false;
                  _userErrorMessage = state.message;
                });
              }
            },
          ),
          BlocListener<UsersTripCollectionBloc, UsersTripCollectionState>(
            listener: (context, state) {
              if (state is UsersTripCollectionLoading) {
                setState(() {
                  _isTripsLoading = true;
                });
              } else if (state is UsersTripCollectionsLoaded) {
                setState(() {
                  _isTripsLoading = false;
                  _tripsErrorMessage = null;
                });
              } else if (state is UsersTripCollectionError) {
                setState(() {
                  _isTripsLoading = false;
                  _tripsErrorMessage = state.message;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<GeneralUserBloc, GeneralUserState>(
          builder: (context, state) {
            if (_isUserLoading || state is GeneralUserLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GeneralUserError) {
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
                      onPressed: _manualRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is UserByIdLoaded) {
              final user = state.user;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Dashboard
                    UserDetailsDashboard(
                      user: user,
                      onEdit: () {
                        context.go('/update-user/${user.id}', extra: user);
                      },
                      onDelete: () {
                        _showDeleteConfirmationDialog(context, user.id ?? '');
                      },
                    ),

                    const SizedBox(height: 32),

                    // Trip collection table (wrapped in a sized box)
                    SizedBox(
                      child: BlocBuilder<UsersTripCollectionBloc, UsersTripCollectionState>(
                        builder: (context, tripState) {
                          if (_isTripsLoading || tripState is UsersTripCollectionLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (tripState is UsersTripCollectionError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading trip records: ${tripState.message}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<UsersTripCollectionBloc>().add(
                                        GetUserTripCollectionsEvent(widget.userId),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (tripState is UsersTripCollectionsLoaded) {
                            return UserTripCollectionTable(
                              tripCollections: tripState.tripCollections,
                              userId: widget.userId,
                              isLoading: false,
                              onRefresh: () {
                                context.read<UsersTripCollectionBloc>().add(
                                  GetUserTripCollectionsEvent(widget.userId),
                                );
                              },
                            );
                          }

                          // Default empty state
                          return const Center(child: Text('No trips found.'));
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            // Fallback
            return const Center(child: Text('Select a user to view details'));
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GeneralUserBloc>().add(DeleteUserEvent(userId));
              context.go('/all-users');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
