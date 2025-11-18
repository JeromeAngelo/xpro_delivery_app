import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';

/// A dialog that shows a searchable list of trips (vehicle list).
/// Returns the selected TripEntity when closed (or null if cancelled).
class VehicleListDialog extends StatefulWidget {
  final List<TripEntity> trips;
  final String? title;

  const VehicleListDialog({
    super.key,
    required this.trips,
    this.title = 'Active Trip/Vehicles',
  });

  /// Helper to show the dialog and get the selected TripEntity.
  static Future<TripEntity?> show(
    BuildContext context,
    List<TripEntity> trips, {
    String? title,
  }) {
    return showDialog<TripEntity>(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 40,
            ),
            child: VehicleListDialog(trips: trips, title: title),
          ),
    );
  }

  @override
  State<VehicleListDialog> createState() => _VehicleListDialogState();
}

class _VehicleListDialogState extends State<VehicleListDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<TripEntity> _filtered;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.trips);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce to avoid aggressive re-filtering while typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final q = _searchController.text.trim().toLowerCase();
      setState(() {
        if (q.isEmpty) {
          _filtered = List.from(widget.trips);
        } else {
          _filtered =
              widget.trips.where((t) {
                final vehicleName =
                    (t.vehicle?.toString() ?? '')
                        .toLowerCase(); // defensive fallback
                final vName =
                    (t.vehicle != null && (t.vehicle as dynamic).name != null)
                        ? ((t.vehicle as dynamic).name as String).toLowerCase()
                        : vehicleName;
                final tripId = (t.tripNumberId ?? '').toLowerCase();
                final userName =
                    (t.user?.name ?? t.user?.email ?? '').toLowerCase();
                return vName.contains(q) ||
                    tripId.contains(q) ||
                    userName.contains(q);
              }).toList();
        }
      });
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search vehicle, trip id or user',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildListTile(TripEntity trip) {
    final vehicleName =
        (trip.vehicle != null && (trip.vehicle as dynamic).name != null)
            ? (trip.vehicle as dynamic).name as String
            : 'Unknown Vehicle';
    final subtitle =
        '${trip.tripNumberId ?? ''}'
        '${(trip.user?.name != null && trip.user!.name!.isNotEmpty) ? ' / ${trip.user!.name}' : ''}';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.12),
        child: const Icon(Icons.local_shipping, color: Colors.black54),
      ),
      title: Text(
        vehicleName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;
    final width = MediaQuery.of(context).size.width * 0.42;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title ?? 'Active Trip/Vehicles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar + list inside a CustomScrollView
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchHeaderDelegate(child: _buildSearchBar()),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final trip = _filtered[index];
                    return _buildListTile(trip);
                  }, childCount: _filtered.length),
                ),

                if (_filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No vehicles found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
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

/// Small delegate to host the search bar as a pinned header inside CustomScrollView.
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
