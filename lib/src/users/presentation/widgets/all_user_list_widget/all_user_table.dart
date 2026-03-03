import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/entity/users_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/all_user_list_widget/all_user_searchbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/all_user_list_widget/all_user_status_chip.dart';

class DeliveryUserDataTable extends StatelessWidget {
  final List<GeneralUserEntity> users;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const DeliveryUserDataTable({
    super.key,
    required this.users,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });
  @override
  Widget build(BuildContext context) {
    // Add debugging to check user data
    for (var user in users) {
      debugPrint(
        '👤 User: ${user.name} | Email: ${user.email} | ID: ${user.id} | Role: ${user.role?.name}',
      );
    }

    return DataTableLayout(
      title: 'Delivery Users',
      searchBar: DeliveryUserSearchBar(
        controller: searchController,
        searchQuery: searchQuery,
        onSearchChanged: onSearchChanged,
      ),
      onCreatePressed: () {
        // Navigate to create delivery user screen
        context.go('/create-users');
      },
      createButtonText: 'Create User',
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Email')),
        //  DataColumn(label: Text('Current Trip')),
        DataColumn(label: Text('User Role')), // Added User Role column
        DataColumn(label: Text('Status')), // Added User Role column

        DataColumn(label: Text('Actions')),
      ],
      rows:
          users.map((user) {
            // Debug each user's email as we create the row
            debugPrint(
              '📧 Creating row for user: ${user.name} with email: ${user.email} and role: ${user.role?.name}',
            );

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage:
                            user.profilePic != null &&
                                    user.profilePic!.isNotEmpty
                                ? NetworkImage(user.profilePic!)
                                : null,
                        child:
                            user.profilePic == null || user.profilePic!.isEmpty
                                ? Text(
                                  user.name?.isNotEmpty == true
                                      ? user.name![0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(user.name ?? 'N/A')),
                    ],
                  ),
                  onTap: () => _navigateToUserDetails(context, user),
                ),
                // Email cell
                DataCell(
                  Text(user.email != null ? user.email! : 'No Email'),
                  onTap: () => _navigateToUserDetails(context, user),
                ),

                // Trip cell
                // DataCell(
                //   user.trip != null
                //       ? InkWell(
                //         onTap: () {
                //           if (user.trip?.id != null) {
                //             context.go('/tripticket/${user.trip!.id}');
                //           }
                //         },
                //         child: Text(
                //           user.trip?.tripNumberId ?? 'N/A',
                //           style: const TextStyle(
                //             color: Colors.blue,
                //             decoration: TextDecoration.underline,
                //           ),
                //         ),
                //       )
                //       : const Text('No Active Trip'),
                // ),

                // User Role cell - NEW
                DataCell(
                  user.role != null
                      ? Chip(
                        label: Text(
                          user.role!.name ?? 'Unknown Role',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: _getRoleColor(user.role!.name),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        visualDensity: VisualDensity.compact,
                      )
                      : const Text('No Role Assigned'),
                  onTap: () => _navigateToUserDetails(context, user),
                ),
                DataCell(AllUserStatusChip(user: user)),
                // Actions cell
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () {
                          // View user details
                          if (user.id != null) {
                            _navigateToUserDetails(context, user);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit',
                        onPressed: () {
                          // Edit user
                          if (user.id != null) {
                            context.go('/update-user/${user.id}');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          _showDeleteConfirmationDialog(context, user);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      isLoading: isLoading,
      dataLength: '${users.length}',
      onDeleted: () {},
    );
  }

  // Helper method to get color based on role name
  Color _getRoleColor(String? roleName) {
    if (roleName == null) return Colors.grey;

    switch (roleName.toLowerCase()) {
      case 'super administrator':
        return Colors.red;
      case 'collection administrator':
        return Colors.purple;
      case 'driver':
        return Colors.blue;
      case 'helper':
        return Colors.green;
      case 'otp code viewer':
        return Colors.orange;
      case 'return administrator':
        return Colors.brown;
      case 'team leader':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method to navigate to trip details
  void _navigateToUserDetails(BuildContext context, GeneralUserEntity user) {
    if (user.id != null) {
      // First load the trip data
      context.read<GeneralUserBloc>().add(GetUserByIdEvent(user.id!));

      // Then navigate to the specific trip view
      context.go('/user/${user.id}');
    }
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    GeneralUserEntity user,
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
                Text('Are you sure you want to delete ${user.name}?'),
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
                if (user.id != null) {
                  context.read<GeneralUserBloc>().add(
                    DeleteUserEvent(user.id!),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
