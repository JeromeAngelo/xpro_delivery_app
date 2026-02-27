import 'package:flutter/material.dart';

import '../../../../core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import '../../../../core/common/widgets/app_structure/status_icons.dart';

class TileForTimeline extends StatelessWidget {
  final DeliveryDataEntity deliveryData;
  final bool isLocalTile;
  final DeliveryUpdateEntity? specificUpdate;

  const TileForTimeline({
    super.key,
    required this.deliveryData,
    this.isLocalTile = false,
    this.specificUpdate,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final latestStatus = _getLatestDeliveryStatus();
    final statusTitle = (latestStatus?.title ?? 'NONE').trim();
    final statusDesc = (latestStatus?.subtitle ?? '').trim();

    final time = latestStatus?.time;
    final timeText = time == null ? '—' : _formatTime(time);

    final tripName = (deliveryData.trip?.name ?? '').trim();
    final address = _buildAddressString().trim();

    final tripUser = deliveryData.trip?.user?.name;

    // NOTE: static text as requested

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: time + status chip
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(
                    title: statusTitle,
                    icon: StatusIcons.getStatusIcon(statusTitle),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Big title: status description
              Text(
                statusDesc.isEmpty ? 'No description' : statusDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              // ── Inner info box (ID + address style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.55,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tripName.isEmpty ? 'ID: —' : 'Route: $tripName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address.isEmpty ? '—' : address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── People row (static text)
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tripUser != null
                          ? 'Assigned to: $tripUser'
                          : 'No one assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  dynamic _getLatestDeliveryStatus() {
    // If we have a specific update, use that
    if (specificUpdate != null) {
      return specificUpdate;
    }

    // Otherwise use the latest delivery update
    final deliveryUpdates = deliveryData.deliveryUpdates.toList();
    return deliveryUpdates.isNotEmpty ? deliveryUpdates.last : null;
  }

  String _buildAddressString() {
    final addressParts = <String>[];

    if (deliveryData.customer?.barangay != null &&
        deliveryData.customer!.barangay!.isNotEmpty) {
      addressParts.add(deliveryData.customer!.barangay!);
    }
    if (deliveryData.customer?.municipality != null &&
        deliveryData.customer!.municipality!.isNotEmpty) {
      addressParts.add(deliveryData.customer!.municipality!);
    }
    if (deliveryData.customer?.province != null &&
        deliveryData.customer!.province!.isNotEmpty) {
      addressParts.add(deliveryData.customer!.province!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : '';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  // String _formatDate(DateTime dateTime) {
  //   final month = dateTime.month.toString().padLeft(2, '0');
  //   final day = dateTime.day.toString().padLeft(2, '0');
  //   final year = dateTime.year;
  //   return '$month/$day/$year';
  // }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = title.trim().toLowerCase();
    final theme = Theme.of(context);

    Color bg;
    Color fg;

    switch (t) {
      case 'queued':
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case 'preparing':
      case 'in transit':
      case 'intransit':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      case 'arrived':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'unloading':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
      case 'received':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade800;
        break;
      case 'delivered':
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade800;
        break;
      case 'cancelled':
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            title.isEmpty ? 'N/A' : title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
