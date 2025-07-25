import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_dashboard.dart';

class SpecificPersonnelDashboard extends StatelessWidget {
  final PersonelEntity personnel;
  final bool isLoading;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SpecificPersonnelDashboard({
    super.key,
    required this.personnel,
    this.isLoading = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return DashboardSummary(
        title: 'Personnel Details',
        items: _buildLoadingItems(),
        isLoading: true,
        crossAxisCount: 2,
        childAspectRatio: 4.0,
      );
    }

    final dashboardItems = [
      DashboardInfoItem(
        icon: Icons.person,
        value: personnel.name ?? 'N/A',
        label: 'Personnel Name',
        iconColor: Colors.blue,
      ),
      DashboardInfoItem(
        icon: Icons.badge,
        value: personnel.id ?? 'N/A',
        label: 'Personnel ID',
        iconColor: Colors.green,
      ),
      DashboardInfoItem(
        icon: Icons.work,
        value: _formatRole(personnel.role?.toString()),
        label: 'Role',
        iconColor: Colors.orange,
      ),
      DashboardInfoItem(
        icon: Icons.assignment,
        value: personnel.isAssigned == true ? 'Assigned' : 'Available',
        label: 'Assignment Status',
        iconColor: personnel.isAssigned == true ? Colors.red : Colors.green,
      ),
      DashboardInfoItem(
        icon: Icons.groups,
        value: _formatDeliveryTeam(personnel.deliveryTeam?.id),
        label: 'Delivery Team',
        iconColor: Colors.purple,
      ),
      DashboardInfoItem(
        icon: Icons.local_shipping,
        value: _formatTrip(personnel.trip?.tripNumberId),
        label: 'Current Trip',
        iconColor: Colors.teal,
      ),
      DashboardInfoItem(
        icon: Icons.calendar_today,
        value: _formatDate(personnel.created),
        label: 'Created Date',
        iconColor: Colors.indigo,
      ),
      DashboardInfoItem(
        icon: Icons.update,
        value: _formatDate(personnel.updated),
        label: 'Last Updated',
        iconColor: Colors.amber,
      ),
    ];

    return DashboardSummary(
      title: 'Personnel Details',
      detailId: personnel.name,
      items: dashboardItems,
      crossAxisCount: 2,
      childAspectRatio: 4.0,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  String _formatRole(String? role) {
    if (role == null) return 'N/A';
    
    // Convert enum format to readable format
    switch (role.toLowerCase().replaceAll('userrole.', '')) {
      case 'teamleader':
        return 'Team Leader';
      case 'helper':
        return 'Helper';
      default:
        return role.replaceAll('UserRole.', '').replaceAll('_', ' ');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDeliveryTeam(String? teamId) {
    if (teamId == null || teamId.isEmpty) return 'No Team Assigned';
    return 'Team $teamId';
  }

  String _formatTrip(String? tripId) {
    if (tripId == null || tripId.isEmpty) return 'No Active Trip';
    return tripId;
  }

  List<DashboardInfoItem> _buildLoadingItems() {
    return [
      DashboardInfoItem(
        icon: Icons.person,
        value: 'Loading...',
        label: 'Personnel Name',
        iconColor: Colors.blue,
      ),
      DashboardInfoItem(
        icon: Icons.badge,
        value: 'Loading...',
        label: 'Personnel ID',
        iconColor: Colors.green,
      ),
      DashboardInfoItem(
        icon: Icons.work,
        value: 'Loading...',
        label: 'Role',
        iconColor: Colors.orange,
      ),
      DashboardInfoItem(
        icon: Icons.assignment,
        value: 'Loading...',
        label: 'Assignment Status',
        iconColor: Colors.grey,
      ),
      DashboardInfoItem(
        icon: Icons.groups,
        value: 'Loading...',
        label: 'Delivery Team',
        iconColor: Colors.purple,
      ),
      DashboardInfoItem(
        icon: Icons.local_shipping,
        value: 'Loading...',
        label: 'Current Trip',
        iconColor: Colors.teal,
      ),
    ];
  }
}
