import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../../core/common/widgets/status_icons.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

import '../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class DeliveryListTile extends StatefulWidget {
  final DeliveryDataEntity delivery;
  final VoidCallback? onTap;
  final bool selectionMode;
  final VoidCallback? onLongPress;
  final ValueChanged<bool> onSelectionChanged;
  final bool isSelected;

  const DeliveryListTile({
    super.key,
    required this.delivery,
    this.onTap,
    required this.selectionMode,
    this.onLongPress,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  State<DeliveryListTile> createState() => _DeliveryListTileState();
}

class _DeliveryListTileState extends State<DeliveryListTile> {
  DeliveryDataState? _cachedState;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listenWhen:
          (previous, current) =>
              current is DeliveryDataLoaded ||
              current is DeliveryDataByIdWatched ||
              current is DeliveryDataError,
      listener: (context, state) {
        if (!mounted) return;
        if (state is DeliveryDataLoaded) {
          if (state.deliveryData.id == widget.delivery.id) {
            setState(() => _cachedState = state);
          }
        } else if (state is DeliveryDataByIdWatched) {
          final model = state.deliveryData;
          if (model != null && model.id == widget.delivery.id) {
            setState(() => _cachedState = DeliveryDataLoaded(model));
          }
        } else if (state is DeliveryDataError) {
          setState(() => _cachedState = state);
        }
      },
      buildWhen:
          (previous, current) =>
              current is DeliveryDataLoaded ||
              current is DeliveryDataByIdWatched ||
              current is DeliveryDataError,
      builder: (context, state) {
        DeliveryDataState? effectiveState;
        if (state is DeliveryDataLoaded &&
            state.deliveryData.id == widget.delivery.id) {
          effectiveState = state;
        } else if (_cachedState is DeliveryDataLoaded &&
            (_cachedState as DeliveryDataLoaded).deliveryData.id ==
                widget.delivery.id) {
          effectiveState = _cachedState;
        } else if (_cachedState is DeliveryDataError) {
          effectiveState = _cachedState;
        } else {
          effectiveState = null;
        }

        DeliveryDataEntity deliveryData = widget.delivery;

        if (effectiveState is DeliveryDataLoaded) {
          deliveryData = effectiveState.deliveryData;
        }

        final storeName = deliveryData.storeName;
        final municipality = deliveryData.municipality;

        // Show shimmer loading if store info is null
        if (storeName == null && municipality == null) {
          return _buildShimmerTile();
        }

        return GestureDetector(
          onLongPress: widget.onLongPress,
          child: Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap:
                  widget.onTap ??
                  () {
                    if (deliveryData.id != null) {
                      context.read<DeliveryDataBloc>().add(
                        GetLocalDeliveryDataByIdEvent(deliveryData.id!),
                      );
                      context.pushReplacement(
                        '/delivery-and-invoice/${deliveryData.id}',
                        extra: deliveryData,
                      );
                    }
                  },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryHeader(context, deliveryData),
                    const SizedBox(height: 12),
                    _buildDeliveryFooter(context, deliveryData),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHeader(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    final storeName = delivery.storeName;
    final municipality = delivery.municipality;
    final province = delivery.province;

    // Format location
    String location = 'Unknown Location';
    if (municipality != null && province != null) {
      location = '$province - $municipality';
    } else if (province != null) {
      location = province;
    } else if (municipality != null) {
      location = municipality;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store icon with red/orange background
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.store,
            color: Theme.of(context).colorScheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        // Store info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName ?? 'No Store Name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Selection checkbox or arrow
        widget.selectionMode
            ? Checkbox(
              value: widget.isSelected,
              onChanged: (val) {
                if (val != null) {
                  widget.onSelectionChanged(val);
                }
              },
            )
            : const Icon(Icons.arrow_forward_ios),
      ],
    );
  }

  Widget _buildDeliveryFooter(
    BuildContext context,
    DeliveryDataEntity delivery,
  ) {
    final invoiceCount = delivery.invoices.length;
    final municipality = delivery.municipality;
    final province = delivery.province;

    // Format location (just province for footer)
    String location = province ?? municipality ?? 'Unknown';

    // Get status using the robust _getDeliveryStatus function
    String status = _getDeliveryStatus(delivery);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Invoice count
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    invoiceCount == 0
                        ? 'No Invoices'
                        : invoiceCount == 1
                        ? '1 Invoice'
                        : '$invoiceCount Invoices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Location
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Status badge with dynamic icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  StatusIcons.getStatusIcon(status),
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DeliveryListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.delivery, widget.delivery) ||
        oldWidget.delivery.id != widget.delivery.id) {
      _cachedState = null;
      return;
    }

    try {
      if (_cachedState is DeliveryDataLoaded) {
        final cachedDelivery =
            (_cachedState as DeliveryDataLoaded).deliveryData;
        final currentDelivery = widget.delivery;

        final cachedUpdates = cachedDelivery.deliveryUpdates.toList();
        final currentUpdates = currentDelivery.deliveryUpdates.toList();

        if (cachedUpdates.length != currentUpdates.length) {
          _cachedState = null;
          return;
        }

        DateTime? _latestFor(List updates) {
          DateTime? latest;
          for (final u in updates) {
            try {
              final dyn = u as dynamic;
              final ts = dyn.lastLocalUpdatedAt ?? dyn.updated ?? dyn.time;
              if (ts != null && (latest == null || ts.isAfter(latest))) {
                latest = ts as DateTime;
              }
            } catch (_) {}
          }
          return latest;
        }

        final cachedLatest = _latestFor(cachedUpdates);
        final currentLatest = _latestFor(currentUpdates);

        if (currentLatest != null &&
            (cachedLatest == null || currentLatest.isAfter(cachedLatest))) {
          _cachedState = null;
          return;
        }
      }
    } catch (_) {
      _cachedState = null;
      return;
    }
  }

  Widget _buildShimmerTile() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Shimmer content same as before
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              children: [
                Container(
                  height: 14,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryStatus(DeliveryDataEntity delivery) {
    final deliveryUpdates = delivery.deliveryUpdates.toList();
    if (deliveryUpdates.isEmpty) return 'Pending';

    DateTime? _tsFor(dynamic u) {
      try {
        final dyn = u as dynamic;
        return dyn.lastLocalUpdatedAt ?? dyn.updated ?? dyn.time;
      } catch (_) {
        try {
          return (u as dynamic).updated ?? (u as dynamic).time;
        } catch (_) {
          return null;
        }
      }
    }

    deliveryUpdates.sort((a, b) {
      final at = _tsFor(a);
      final bt = _tsFor(b);
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return at.compareTo(bt);
    });

    final latest = deliveryUpdates.last;
    try {
      final dyn = latest as dynamic;
      return dyn.title ?? 'Pending';
    } catch (_) {
      return (latest.title != null) ? latest.title! : 'Pending';
    }
  }
}
