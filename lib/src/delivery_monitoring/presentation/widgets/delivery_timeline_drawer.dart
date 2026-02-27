import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import '../../../../core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../../../../core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import '../../../../core/common/widgets/reusable_widgets/custom_timeline.dart';
import 'tile_for_timeline.dart';

class DeliveryTimelineDrawer extends StatelessWidget {
  const DeliveryTimelineDrawer({
    super.key,
    required this.onRefresh,
    required this.formatDate,
  });

  final VoidCallback onRefresh;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 380,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onRefresh: onRefresh),
            const Divider(height: 1),

            Expanded(
              child: BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
                listenWhen: (p, c) => c is DeliveryDataError,
                listener: (context, state) {
                  if (state is DeliveryDataError) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(12),
                        ),
                      );
                  }
                },
                buildWhen:
                    (p, c) =>
                        c is DeliveryDataLoading ||
                        c is DeliveryDataError ||
                        c is AllDeliveryDataWithTripsLoaded ||
                        c is AllDeliveryDataLoaded,
                builder: (context, state) {
                  if (state is DeliveryDataLoading) {
                    return const _LoadingList();
                  }

                  if (state is DeliveryDataError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: onRefresh,
                    );
                  }

                  final List<DeliveryDataEntity> deliveries = switch (state) {
                    AllDeliveryDataWithTripsLoaded s => s.deliveryData,
                    AllDeliveryDataLoaded s => s.deliveryData,
                    _ => const <DeliveryDataEntity>[],
                  };

                  if (deliveries.isEmpty) {
                    return const _EmptyView();
                  }

                  // ✅ NEW: Timeline design (delivery updates only)
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: _DeliveryOnlyTimeline(deliveries: deliveries),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOnlyTimeline extends StatelessWidget {
  const _DeliveryOnlyTimeline({required this.deliveries});

  final List<DeliveryDataEntity> deliveries;

  DateTime _updateTs(DeliveryUpdateEntity u) {
    return u.time ??
        u.created ??
        u.updated ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _statusKey(DeliveryUpdateEntity u) {
    final t = (u.title ?? '').trim().toLowerCase();
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// ✅ Keep only latest update per status (per delivery)
  List<DeliveryUpdateEntity> _dedupeDeliveryUpdates(
    Iterable<DeliveryUpdateEntity> updates,
  ) {
    final list = updates.toList();

    // newest -> oldest so the first time we see a status is the latest one
    list.sort((a, b) => _updateTs(b).compareTo(_updateTs(a)));

    final seenStatus = <String>{};
    final seenId = <String>{}; // optional if entity has id

    final out = <DeliveryUpdateEntity>[];

    for (final u in list) {
      // optional: dedupe by update id if exists
      final dyn = u as dynamic;
      final String? uid =
          (() {
            try {
              final v = dyn.id;
              if (v == null) return null;
              final s = v.toString().trim();
              return s.isEmpty ? null : s;
            } catch (_) {
              return null;
            }
          })();

      if (uid != null) {
        if (seenId.contains(uid)) continue;
        seenId.add(uid);
      }

      final key = _statusKey(u);
      if (key.isEmpty) continue;

      if (seenStatus.contains(key)) continue;
      seenStatus.add(key);

      out.add(u);
    }

    return out; // keep newest-first
  }

  @override
  Widget build(BuildContext context) {
    final items = <_TimelineItem>[];

    for (final delivery in deliveries) {
      final rawUpdates = delivery.deliveryUpdates.toList();
      final deduped = _dedupeDeliveryUpdates(rawUpdates);

      for (final u in deduped) {
        items.add(
          _TimelineItem(
            date: _updateTs(u),
            delivery: delivery,
            deliveryUpdate: u,
          ),
        );
      }
    }

    // Sort all items by date (latest first)
    items.sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return const _EmptyView();
    }

    return CustomTimelineTileBuilder.connected(
      physics: const AlwaysScrollableScrollPhysics(),
      nodePosition: 0.01,
      
      itemCount: items.length,
      contentsBuilder: (_, index) {
        final item = items[index];

        // ✅ Uses your existing timeline tile UI
        return TileForTimeline(
          deliveryData: item.delivery,
          specificUpdate: item.deliveryUpdate,
        );
      },
      indicatorBuilder: (_, index) {
        final isLatest = index == 0;

        if (isLatest) {
          return Icon(
            Icons.local_shipping_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 15,
          );
        }

        return CustomDotIndicator(
          color: Theme.of(context).colorScheme.outline,
          size: 12,
        );
      },
      connectorBuilder: (_, index, type) {
        final isLatest = index == 0;
        return CustomDecoratedLineConnector(
          decoration: BoxDecoration(
            color:
                isLatest
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
          ),
        );
      },
    );
  }
}

class _TimelineItem {
  final DateTime date;
  final DeliveryDataEntity delivery;
  final DeliveryUpdateEntity deliveryUpdate;

  _TimelineItem({
    required this.date,
    required this.delivery,
    required this.deliveryUpdate,
  });
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.close_rounded,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _StatusPill extends StatelessWidget {
//   const _StatusPill({required this.text});

//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = text.trim().toLowerCase();

//     Color bg;
//     Color fg;

//     // Simple professional mapping (adjust if you want)
//     switch (t) {
//       case 'pending':
//         bg = Colors.orange.shade100;
//         fg = Colors.orange.shade800;
//         break;
//       case 'in transit':
//       case 'intransit':
//         bg = Colors.blue.shade100;
//         fg = Colors.blue.shade800;
//         break;
//       case 'arrived':
//         bg = Colors.green.shade100;
//         fg = Colors.green.shade800;
//         break;
//       case 'unloading':
//         bg = Colors.purple.shade100;
//         fg = Colors.purple.shade800;
//         break;
//       case 'received':
//       case 'mark as received':
//         bg = Colors.teal.shade100;
//         fg = Colors.teal.shade800;
//         break;
//       case 'delivered':
//       case 'end delivery':
//         bg = Colors.indigo.shade100;
//         fg = Colors.indigo.shade800;
//         break;
//       case 'cancelled':
//         bg = Colors.red.shade100;
//         fg = Colors.red.shade800;
//         break;
//       default:
//         bg = Colors.grey.shade200;
//         fg = Colors.grey.shade800;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: fg.withOpacity(0.25)),
//       ),
//       child: Text(
//         text.isEmpty ? 'N/A' : text,
//         style: Theme.of(context).textTheme.labelSmall?.copyWith(
//           color: fg,
//           fontWeight: FontWeight.w800,
//           letterSpacing: 0.2,
//         ),
//       ),
//     );
//   }
// }

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder:
          (_, __) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No timeline data yet',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull to refresh or wait for delivery updates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load timeline',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
