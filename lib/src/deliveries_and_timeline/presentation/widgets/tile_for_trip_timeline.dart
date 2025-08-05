import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';

import 'package:x_pro_delivery_app/core/common/widgets/trip_update_icons.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class TileForTripTimeline extends StatelessWidget {
  final TripUpdateEntity update;
  final bool isFirst;
  final bool isLast;

  const TileForTripTimeline({
    super.key,
    required this.update,
    this.isFirst = false,
    this.isLast = false,
  });

  String _formatStatusName(String? status) {
    if (status == null || status.isEmpty) {
      debugPrint('📝 Using default status name');
      return 'Trip Update';
    }

    debugPrint('🔤 Formatting status: $status');
    
    // Try to parse the status using TripUpdateStatus enum
    try {
      final tripStatus = TripUpdateStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toLowerCase(),
        orElse: () => TripUpdateStatus.none,
      );
      
      switch (tripStatus) {
        case TripUpdateStatus.none:
          return 'Trip Update';
        case TripUpdateStatus.generalUpdate:
          return 'General Update';
        case TripUpdateStatus.vehicleBreakdown:
          return 'Vehicle Breakdown';
        case TripUpdateStatus.refuelling:
          return 'Refuelling';
        case TripUpdateStatus.roadClosure:
          return 'Road Closure';
        case TripUpdateStatus.others:
          return 'Others';
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse status enum: $e');
      // Fallback to previous formatting method
      final words = status.split(RegExp(r'(?=[A-Z])'));
      return words.map((word) => word.capitalize()).join(' ');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$month/$day/$year';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is UserTripLoaded) {
          // Debug: Show time conversion
          final utcTime = update.date ?? DateTime.now();
          final localTime = utcTime.toLocal();
          debugPrint('🕐 TRIP TIME: UTC: $utcTime → Local: $localTime');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TripUpdateIcons.getStatusIcon(update.status?.name ?? ''),
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatStatusName(update.status?.name ?? ''),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (update.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              update.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (update.latitude != null && update.longitude != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${update.latitude}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Long: ${update.longitude}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime((update.date ?? DateTime.now()).toLocal()),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Text(
                              _formatDate((update.date ?? DateTime.now()).toLocal()),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
