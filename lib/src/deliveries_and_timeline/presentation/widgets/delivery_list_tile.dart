import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

import '../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

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
        // Only cache states that belong to this delivery item to avoid
        // overwriting the tile with unrelated delivery updates.
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
          // Optionally cache errors only if they relate to this delivery
          setState(() => _cachedState = state);
        }
      },
      buildWhen:
          (previous, current) =>
              current is DeliveryDataLoaded ||
              current is DeliveryDataByIdWatched ||
              current is DeliveryDataError,
      builder: (context, state) {
        // Prioritize cached state for offline-first behavior
        // Use the most relevant state: prefer an up-to-date bloc state for
        // this delivery, otherwise fall back to a cached state for this tile.
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

        // Determine which delivery data to display
        DeliveryDataEntity deliveryData = widget.delivery;

        if (effectiveState is DeliveryDataLoaded) {
          deliveryData = effectiveState.deliveryData;
        }

        final storeName = deliveryData.storeName;
        final municipality = deliveryData.municipality;
        final invoices = deliveryData.invoices;

        // Debug: log delivery and updates info to help trace UI state
        try {
          final updatesList =
              deliveryData.deliveryUpdates.toList().map((u) {
                try {
                  final dyn = u as dynamic;
                  final lastLocal = dyn.lastLocalUpdatedAt?.toIso8601String();
                  final updated = dyn.updated?.toIso8601String();
                  final time = dyn.time?.toIso8601String();
                  return '${dyn.title ?? 'null'}|lastLocal:$lastLocal|updated:$updated|time:$time';
                } catch (_) {
                  return u.title ?? 'null';
                }
              }).toList();

          final computedStatus = _getDeliveryStatus(deliveryData);
          debugPrint(
            'Tile build => id=${deliveryData.id} store=$storeName updates=${updatesList.length} effectiveState=${effectiveState?.runtimeType} status=$computedStatus',
          );
          debugPrint('Tile updates => $updatesList');
        } catch (e, s) {
          debugPrint('Tile debug failure: $e\n$s');
        }

        // Show shimmer loading if store info is null
        if (storeName == null && municipality == null) {
          return _buildShimmerTile();
        }

        return GestureDetector(
          onLongPress: widget.onLongPress,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.store,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName ?? 'No Store Name',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${invoices.length} ${invoices.length == 1 ? 'Invoice' : 'Invoices'}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                municipality ?? 'No Address',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getDeliveryStatus(deliveryData),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant DeliveryListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear cached state when the parent provides a new delivery object
    // (not just when the id changes). The parent may supply a new instance
    // with updated relations while keeping the same id; clearing the cache
    // ensures the tile shows the fresh data instead of stale cached state.
    if (!identical(oldWidget.delivery, widget.delivery) ||
        oldWidget.delivery.id != widget.delivery.id) {
      _cachedState = null;
      return;
    }

    // If the widget was updated but the same DeliveryData instance was
    // passed (in-place mutation), we may still have stale cached state
    // inside this tile. Compare the cached state's delivery updates with
    // the current delivery object; if the current object appears newer
    // (more updates or a more recent lastLocalUpdatedAt), clear cache so
    // the tile rebuilds from the fresh delivery object.
    try {
      if (_cachedState is DeliveryDataLoaded) {
        final cachedDelivery =
            (_cachedState as DeliveryDataLoaded).deliveryData;
        final currentDelivery = widget.delivery;

        final cachedUpdates = cachedDelivery.deliveryUpdates.toList();
        final currentUpdates = currentDelivery.deliveryUpdates.toList();

        // If counts differ, prefer current (clear cache)
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
      // If any unexpected error occurs, fall back to clearing the cache
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
