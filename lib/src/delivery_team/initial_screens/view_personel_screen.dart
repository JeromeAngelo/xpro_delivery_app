import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/empty_screen_message.dart';

class ViewPersonelScreen extends StatefulWidget {
  final DeliveryTeamEntity? deliveryTeam;

  const ViewPersonelScreen({
    super.key,
    this.deliveryTeam,
  });

  @override
  State<ViewPersonelScreen> createState() => _ViewPersonelScreenState();
}

class _ViewPersonelScreenState extends State<ViewPersonelScreen> {
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPersonelData();
  }

  void _loadPersonelData() {
    if (!_isDataInitialized && widget.deliveryTeam == null) {
      // If no delivery team data passed, try to load it
      context.read<DeliveryTeamBloc>().add( LoadDeliveryTeamByIdEvent(widget.deliveryTeam!.id!));
      _isDataInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Team Personnel'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildPersonelContent(),
      ),
    );
  }

  Future<void> _refreshData() async {
    if (widget.deliveryTeam != null) {
      // Refresh delivery team data
      context.read<DeliveryTeamBloc>().add( LoadDeliveryTeamByIdEvent(widget.deliveryTeam!.id!));
    }
    setState(() {});
  }

  Widget _buildPersonelContent() {
    // If delivery team data is passed directly, use it
    if (widget.deliveryTeam != null) {
      return _buildPersonelList(widget.deliveryTeam!.personels);
    }

    // Otherwise, listen to delivery team bloc
    return BlocBuilder<DeliveryTeamBloc, DeliveryTeamState>(
      builder: (context, state) {
        debugPrint('🔍 PersonelScreen state: ${state.runtimeType}');

        if (state is DeliveryTeamLoading) {
          return const _LoadingPersonelWidget();
        }

        if (state is DeliveryTeamError) {
          return _ErrorPersonelWidget(
            message: state.message,
            onRetry: _loadPersonelData,
          );
        }

        if (state is DeliveryTeamLoaded) {
          debugPrint('✅ Delivery team loaded with ${state.deliveryTeam.personels.length} personnel');
          return _buildPersonelList(state.deliveryTeam.personels);
        }

        // if (state is DeliveryTeamLoaded && state.deliveryTeams.isNotEmpty) {
        //   final firstTeam = state.deliveryTeams.first;
        //   debugPrint('✅ Using first team with ${firstTeam.personels.length} personnel');
        //   return _buildPersonelList(firstTeam.personels);
        // }

        return const EmptyScreenMessage(message: "No Personnel Data Available");
      },
    );
  }

  Widget _buildPersonelList(List<PersonelEntity> personels) {
    if (personels.isEmpty) {
      return const EmptyScreenMessage(message: "No Personnel Assigned");
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PersonelSummaryCard(personels: personels),
          const SizedBox(height: 20),
          ...personels.map((personel) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PersonelDetailCard(personel: personel),
          )),
        ],
      ),
    );
  }
}

class _PersonelSummaryCard extends StatelessWidget {
  final List<PersonelEntity> personels;

  const _PersonelSummaryCard({required this.personels});

  @override
  Widget build(BuildContext context) {
    final teamLeaders = personels.where((p) => p.role == UserRole.teamLeader).length;
    final helpers = personels.where((p) => p.role == UserRole.helper).length;
    final others = personels.where((p) => p.role != UserRole.teamLeader && p.role != UserRole.helper).length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Overview',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${personels.length} Total Members',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Team Leaders',
                    teamLeaders.toString(),
                    Icons.star,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Helpers',
                    helpers.toString(),
                    Icons.handyman,
                    Colors.green,
                  ),
                ),
                if (others > 0)
                  Expanded(
                    child: _buildSummaryItem(
                      context,
                      'Others',
                      others.toString(),
                      Icons.person,
                      Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PersonelDetailCard extends StatelessWidget {
  final PersonelEntity personel;

  const _PersonelDetailCard({required this.personel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PersonelHeaderSection(personel: personel),
            const SizedBox(height: 16),
            _PersonelDetailsSection(personel: personel),
            const SizedBox(height: 16),
            _PersonelTimelineSection(personel: personel),
          ],
        ),
      ),
    );
  }
}

class _PersonelHeaderSection extends StatelessWidget {
  final PersonelEntity personel;

  const _PersonelHeaderSection({required this.personel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: _getRoleColor(personel.role),
          child: Text(
            personel.name?.substring(0, 1).toUpperCase() ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                personel.name ?? 'No Name',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _RoleBadge(role: personel.role),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.teamLeader:
        return Colors.blue;
      case UserRole.helper:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _PersonelDetailsSection extends StatelessWidget {
  final PersonelEntity personel;

  const _PersonelDetailsSection({required this.personel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personnel Information',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          'Collection ID',
          personel.collectionId ?? 'Not Available',
          Icons.badge,
        ),
        const Divider(),
        _buildDetailRow(
          context,
          'Collection Name',
          personel.collectionName ?? 'Not Available',
          Icons.folder,
        ),
        if (personel.deliveryTeam.target != null) ...[
          const Divider(),
          _buildDetailRow(
            context,
            'Delivery Team',
            personel.deliveryTeam.target!.id ?? 'Not Available',
            Icons.group,
          ),
        ],
        if (personel.trip.target != null) ...[
          const Divider(),
          _buildDetailRow(
            context,
            'Trip Assignment',
            personel.trip.target!.tripNumberId ?? 'Not Available',
            Icons.assignment,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonelTimelineSection extends StatelessWidget {
  final PersonelEntity personel;

  const _PersonelTimelineSection({required this.personel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTimelineItem(
          context,
          'Joined Team',
          personel.created,
          Icons.person_add,
        ),
        if (personel.updated != null)
          _buildTimelineItem(
            context,
            'Last Updated',
            personel.updated,
            Icons.update,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    DateTime? date,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole? role;

  const _RoleBadge({this.role});

  @override
  Widget build(BuildContext context) {
    final roleText = _getRoleText(role);
    final roleColor = _getRoleColor(role);
    final roleIcon = _getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, size: 16, color: roleColor),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole? role) {
    switch (role) {
      case UserRole.teamLeader:
        return 'TEAM LEADER';
      case UserRole.helper:
        return 'HELPER';
     
      default:
        return 'UNKNOWN';
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.teamLeader:
        return Colors.blue;
      case UserRole.helper:
        return Colors.green;
     
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.teamLeader:
        return Icons.star;
      case UserRole.helper:
        return Icons.handyman;
     
      default:
        return Icons.person;
    }
  }
}

// ADDED: Loading state widget for when personnel data is being fetched
class _LoadingPersonelWidget extends StatelessWidget {
  const _LoadingPersonelWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading personnel information...'),
        ],
      ),
    );
  }
}

// ADDED: Error state widget for when there's an error loading data
class _ErrorPersonelWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorPersonelWidget({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Personnel Data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

// // ADDED: Empty personnel widget for when no personnel are found
// class _EmptyPersonelWidget extends StatelessWidget {
//   const _EmptyPersonelWidget();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.people_outline,
//             size: 64,
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No Personnel Found',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'No team members have been assigned to this delivery team.',
//             style: Theme.of(context).textTheme.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ADDED: Personnel statistics widget
// class _PersonelStatisticsCard extends StatelessWidget {
//   final List<PersonelEntity> personels;

//   const _PersonelStatisticsCard({required this.personels});

//   @override
//   Widget build(BuildContext context) {
//     final totalPersonel = personels.length;
//     final activePersonel = personels.where((p) => p.trip.target != null).length;
//     final availablePersonel = totalPersonel - activePersonel;

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Team Statistics',
//               style: Theme.of(context).textTheme.titleMedium!.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildStatItem(
//                     context,
//                     'Total',
//                     totalPersonel.toString(),
//                     Icons.groups,
//                     Colors.blue,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildStatItem(
//                     context,
//                     'Active',
//                     activePersonel.toString(),
//                     Icons.work,
//                     Colors.green,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildStatItem(
//                     context,
//                     'Available',
//                     availablePersonel.toString(),
//                     Icons.person_outline,
//                     Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 32),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.headlineSmall!.copyWith(
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall!.copyWith(
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }
// }

// ADDED: Personnel search and filter widget
class _PersonelSearchWidget extends StatefulWidget {
  final List<PersonelEntity> personels;
  final Function(List<PersonelEntity>) onFiltered;

  const _PersonelSearchWidget({
    required this.personels,
    required this.onFiltered,
  });

  @override
  State<_PersonelSearchWidget> createState() => _PersonelSearchWidgetState();
}

class _PersonelSearchWidgetState extends State<_PersonelSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPersonels);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPersonels() {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.personels.where((personel) {
      final nameMatch = personel.name?.toLowerCase().contains(query) ?? false;
      final roleMatch = _selectedRole == null || personel.role == _selectedRole;
      return nameMatch && roleMatch;
    }).toList();

    widget.onFiltered(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search personnel...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole?>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Filter by Role',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<UserRole?>(
                  value: null,
                  child: Text('All Roles'),
                ),
                ...UserRole.values.map((role) => DropdownMenuItem<UserRole?>(
                  value: role,
                  child: Text(_getRoleText(role)),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
                _filterPersonels();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.teamLeader:
        return 'Team Leader';
      case UserRole.helper:
        return 'Helper';
      
    }
  }
}

