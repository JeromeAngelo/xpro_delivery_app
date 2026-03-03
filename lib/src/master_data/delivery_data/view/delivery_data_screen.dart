import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/delivery_data_screen_widget/delivery_data_error_widget.dart';
import 'package:xpro_delivery_admin_app/src/master_data/delivery_data/widgets/delivery_data_screen_widget/delivery_data_table.dart';
class DeliveryDataScreen extends StatefulWidget {
  const DeliveryDataScreen({super.key});

  @override
  State<DeliveryDataScreen> createState() => _DeliveryDataScreenState();
}

class _DeliveryDataScreenState extends State<DeliveryDataScreen> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _statusFilter; // ✅ NEW (null = no filter)

  @override
  void initState() {
    super.initState();
    context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataWithTripsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Same status logic as DeliveryDataStatusChip, but returns label for filtering
  String _getLatestDeliveryStatusLabel(DeliveryDataEntity delivery) {
    if (delivery.deliveryUpdates.isNotEmpty) {
      final sortedUpdates = List.of(delivery.deliveryUpdates);
      sortedUpdates.sort((a, b) {
        final timeA = a.time ?? a.created ?? DateTime.now();
        final timeB = b.time ?? b.created ?? DateTime.now();
        return timeB.compareTo(timeA);
      });

      final latestUpdate = sortedUpdates.first;
      final updateTitle = latestUpdate.title?.toLowerCase().trim() ?? '';

      switch (updateTitle) {
        case 'arrived':
          return 'Arrived';
        case 'unloading':
          return 'Unloading';
        case 'mark as undelivered':
          return 'Undelivered';
        case 'in transit':
          return 'In Transit';
        case 'pending':
          return 'Pending';
        case 'mark as received':
          return 'Received';
        case 'end delivery':
          return 'Delivered';
        default:
          return latestUpdate.title ?? 'Unknown';
      }
    }
    return 'No Updates';
  }

  // ✅ Apply search + status filter on FULL list
  List<DeliveryDataEntity> _applyFilters(List<DeliveryDataEntity> list) {
    var data = list;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      data = data.where((delivery) {
        return (delivery.deliveryNumber?.toLowerCase().contains(query) ?? false) ||
            (delivery.customer?.name?.toLowerCase().contains(query) ?? false) ||
            (delivery.invoice?.name?.toLowerCase().contains(query) ?? false) ||
            (delivery.refID?.toLowerCase().contains(query) ?? false) ||
            (delivery.trip?.tripNumberId?.toLowerCase().contains(query) ?? false) ||
            (delivery.customer?.municipality?.toLowerCase().contains(query) ?? false) ||
            (delivery.customer?.province?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // ✅ Status filter (ONLY if user set a filter)
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      data = data
          .where((delivery) => _getLatestDeliveryStatusLabel(delivery) == _statusFilter)
          .toList();
    }

    return data;
  }

  // ✅ Paginate after filtering
  List<DeliveryDataEntity> _paginate(List<DeliveryDataEntity> data) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= data.length) return const <DeliveryDataEntity>[];

    final endIndex = (startIndex + _itemsPerPage > data.length)
        ? data.length
        : startIndex + _itemsPerPage;

    return data.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/delivery-list',
      onNavigate: (route) => context.go(route),
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          if (state is DeliveryDataInitial) {
            context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataWithTripsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeliveryDataLoading) {
            return DeliveryDataTable(
              deliveryData: const <DeliveryDataEntity>[],
              isLoading: true,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
              // ✅ NEW: table will call this when filter applied
              onStatusFilterChanged: (status) {
                setState(() {
                  _statusFilter = status; // null clears filter
                  _currentPage = 1;
                });
              },
            );
          }

          if (state is DeliveryDataError) {
            return DeliveryDataErrorWidget(
              errorMessage: state.message,
              onRetry: () {
                context.read<DeliveryDataBloc>().add(const GetAllDeliveryDataWithTripsEvent());
              },
            );
          }

          // ✅ Handles both AllDeliveryDataWithTripsLoaded and DeliveryDataByTripLoaded
          final List<DeliveryDataEntity>? baseList = switch (state) {
            AllDeliveryDataWithTripsLoaded s => s.deliveryData,
            DeliveryDataByTripLoaded s => s.deliveryData,
            _ => null,
          };

          if (baseList != null) {
            // ✅ 1) filter full list
            final filtered = _applyFilters(baseList);

            // ✅ 2) compute pages AFTER filtering
            _totalPages = (filtered.length / _itemsPerPage).ceil();
            if (_totalPages == 0) _totalPages = 1;

            // ✅ keep current page valid
            if (_currentPage > _totalPages) _currentPage = 1;

            // ✅ 3) paginate AFTER filtering
            final paginated = _paginate(filtered);

            return DeliveryDataTable(
              deliveryData: paginated,
              isLoading: false,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
              // ✅ NEW: full filtering trigger
              onStatusFilterChanged: (status) {
                setState(() {
                  _statusFilter = status;
                  _currentPage = 1;
                });
              },
            );
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No delivery data available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}