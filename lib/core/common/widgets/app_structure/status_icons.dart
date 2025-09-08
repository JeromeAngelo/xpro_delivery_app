import 'package:flutter/material.dart';

class StatusIcons {
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return Icons.location_on;

      case 'unloading':
        return Icons.unarchive;
      case 'mark as undelivered':
        return Icons.warning;
      case 'in transit':
        return Icons.local_shipping;
      case 'waiting for customer':
        return Icons.watch;
      case 'pending':
        return Icons.pending;
      case 'mark as received':
        return Icons.get_app_rounded;
      case 'end delivery':
        return Icons.done_all_outlined;

      default:
        return Icons.update;
    }
  }
}
