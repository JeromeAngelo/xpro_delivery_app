import 'package:flutter/material.dart';

class TripUpdateIcons {
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'none':
        return Icons.no_cell_sharp;
      case 'vehicleBreakdown':
        return Icons.car_crash_rounded;
      case 'generalUpdate':
        return Icons.update_outlined;
      case 'roadClosure':
        return Icons.edit_road_rounded;

      case 'refuelling':
        return Icons.local_gas_station;
      case 'others':
        return Icons.more_horiz;
      default:
        return Icons.info;
    }
  }
}
