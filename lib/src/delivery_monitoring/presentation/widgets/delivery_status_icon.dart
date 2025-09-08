import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/status_icons.dart';

class DeliveryStatusData {
  final String name;
  final IconData icon;
  final Color color;
  final String subtitle;

  DeliveryStatusData({
    required this.name,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  // Factory constructor to create from status name
  factory DeliveryStatusData.fromName(String name) {
    return _getStatusByName(name);
  }
}

// Helper function to get status data by name
DeliveryStatusData _getStatusByName(String name) {
  final statusName = name.toLowerCase();

  switch (statusName) {
    case 'pending':
      return DeliveryStatusData(
        name: 'Pending',
        icon: StatusIcons.getStatusIcon('pending'),
        color: Colors.grey,
        subtitle: 'Waiting to Accept The Trip',
      );
    case 'in transit':
      return DeliveryStatusData(
        name: 'In Transit',
        subtitle: 'Truck is on the way to destination',
        icon: StatusIcons.getStatusIcon('in transit'),
        color: Colors.blue,
      );
    case 'arrived':
      return DeliveryStatusData(
        name: 'Arrived',
        icon: StatusIcons.getStatusIcon('arrived'),
        color: Colors.orange,
        subtitle: 'Truck has arrived',
      );
    case 'waiting for customer':
      return DeliveryStatusData(
        name: 'Waiting for Customer',
        icon: StatusIcons.getStatusIcon('waiting for customer'),
        color: Colors.yellow,
        subtitle: 'waiting for customer at location',
      );
    case 'unloading':
      return DeliveryStatusData(
        name: 'Unloading',
        icon: StatusIcons.getStatusIcon('unloading'),
        color: Colors.purple,
        subtitle: 'Unloading items from truck',
      );

    case 'mark as received':
      return DeliveryStatusData(
        name: 'Mark as Received',
        icon: StatusIcons.getStatusIcon('mark as received'),
        color: Colors.green,
        subtitle: 'Customer Received Delivery',
      );

    case 'end delivery':
      return DeliveryStatusData(
        name: 'Completed',
        icon: StatusIcons.getStatusIcon('end delivery'),
        color: Colors.teal,
        subtitle: 'Delivery Completed',
      );
    case 'mark as undelivered':
      return DeliveryStatusData(
        name: 'Mark as Undelivered',
        icon: StatusIcons.getStatusIcon('mark as undelivered'),
        color: Colors.red,
        subtitle: 'Unable to Deliver',
      );
    default:
      return DeliveryStatusData(
        name: 'Unknown',
        icon: Icons.help_outline,
        color: Colors.grey,
        subtitle: '',
      );
  }
}

// List of all delivery statuses for the monitoring screen
List<DeliveryStatusData> getAllDeliveryStatuses() {
  return [
    DeliveryStatusData.fromName('pending'),
    DeliveryStatusData.fromName('in transit'),
    DeliveryStatusData.fromName('arrived'),
    DeliveryStatusData.fromName('waiting for customer'),

    DeliveryStatusData.fromName('unloading'),
    DeliveryStatusData.fromName('mark as received'),

    DeliveryStatusData.fromName('end delivery'),
    DeliveryStatusData.fromName('mark as undelivered'),
  ];
}
