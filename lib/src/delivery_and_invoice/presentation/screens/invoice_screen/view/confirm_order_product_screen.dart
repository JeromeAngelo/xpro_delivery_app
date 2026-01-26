import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_product_list.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_summary_order_product_btn.dart';

import '../../../../../../core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart' show DeliveryDataBloc;
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import '../../../../../../core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../../../../../../core/common/app/features/users/auth/bloc/auth_bloc.dart';
import '../../../../../../core/common/app/features/users/auth/bloc/auth_state.dart';
class ConfirmOrderProductScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final String deliveryDataId;

  const ConfirmOrderProductScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.deliveryDataId,
  });

  @override
  State<ConfirmOrderProductScreen> createState() =>
      _ConfirmOrderProductScreenState();
}

class _ConfirmOrderProductScreenState extends State<ConfirmOrderProductScreen>
    with AutomaticKeepAliveClientMixin {
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");

  late final AuthBloc _authBloc;
  late final DeliveryDataBloc _deliveryDataBloc;

  bool _isInitialized = false;
  bool _isDataInitialized = false;
  bool _isLoading = true;

  String? _currentTripId;
  List<DeliveryDataEntity> _currentDeliveries = [];

  StreamSubscription? _authSubscription;
  StreamSubscription? _deliverySubscription;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _deliveryDataBloc = context.read<DeliveryDataBloc>();
  }

  void _setupListeners() {
    if (_isInitialized) return;

    _authSubscription = _authBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is UserTripLoaded && (state.trip.id ?? '').isNotEmpty) {
        final tripId = state.trip.id!.trim();

        if (!_isDataInitialized || _currentTripId != tripId) {
          _currentTripId = tripId;
          _loadDeliveryDataForTrip(tripId);
        }
      }
    });

    _deliverySubscription = _deliveryDataBloc.stream.listen((state) {
      if (!mounted) return;

      if (state is DeliveryDataByTripLoaded) {
        setState(() {
          _currentDeliveries = state.deliveryData;
          _isLoading = false;
          _isDataInitialized = true;
        });
      }

      if (state is DeliveryDataError) {
        setState(() => _isLoading = false);
      }
    });

    _isInitialized = true;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1) SharedPrefs trip
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final tripData = userData['trip'] as Map<String, dynamic>?;

      final tripId = (tripData?['id'] ?? '').toString().trim();
      if (tripId.isNotEmpty) {
        _currentTripId = tripId;
        _loadDeliveryDataForTrip(tripId);
        return;
      }
    }

    // 2) AuthBloc fallback
    final authState = _authBloc.state;
    if (authState is UserTripLoaded && (authState.trip.id ?? '').isNotEmpty) {
      final tripId = authState.trip.id!.trim();
      _currentTripId = tripId;
      _loadDeliveryDataForTrip(tripId);
      return;
    }

    // 3) No trip → no crash
    setState(() => _isLoading = false);
  }

  void _loadDeliveryDataForTrip(String tripId) {
    debugPrint(
      '📦 ConfirmOrderProductScreen: loading delivery data tripId=$tripId',
    );
    _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));
  }

  Future<void> _refreshData() async {
    final tripId = (_currentTripId ?? '').trim();
    if (tripId.isEmpty) {
      await _loadData();
      return;
    }

    debugPrint('🔄 ConfirmOrderProductScreen: refreshing tripId=$tripId');
    _loadDeliveryDataForTrip(tripId);
  }

  /// ✅ Find the deliveryData that contains the invoiceId
  DeliveryDataEntity? _findDeliveryByInvoiceId(
    List<DeliveryDataEntity> deliveries,
  ) {
    final invoiceId = widget.invoiceId.trim();

    for (final d in deliveries) {
      // ToMany invoices
      try {
        for (final inv in d.invoices) {
          if ((inv.id ?? '').toString().trim() == invoiceId) return d;
        }
      } catch (_) {}

      // fallback if there is ToOne invoice
      try {
        final directInvoiceId = (d.invoice.target?.id ?? '').toString().trim();
        if (directInvoiceId == invoiceId) return d;
      } catch (_) {}
    }
    return null;
  }

  /// ✅ Filter invoice items ONLY for this invoiceId (with fallback)
  List<InvoiceItemsEntity> _filterItemsForInvoice(DeliveryDataEntity delivery) {
    final invoiceId = widget.invoiceId.trim();
    final allItems = delivery.invoiceItems.toList();

    final filtered = allItems.where((item) {
      final viaTarget = (item.invoiceData.target?.id ?? '').toString().trim();

      String viaRaw = '';
      try {
        viaRaw = (item.invoiceDataId ?? '').toString().trim();
      } catch (_) {
        viaRaw = '';
      }

      return viaTarget == invoiceId || viaRaw == invoiceId;
    }).toList();

    debugPrint('🧾 ConfirmOrderProductScreen invoice-items filter');
    debugPrint('   🎯 invoiceId=$invoiceId');
    debugPrint('   📦 allItems=${allItems.length}');
    debugPrint('   ✅ filteredItems=${filtered.length}');

    // ✅ IMPORTANT FALLBACK:
    // If no relation exists yet, DO NOT show empty screen.
    if (filtered.isEmpty && allItems.isNotEmpty) {
      debugPrint('⚠️ No invoiceItems matched invoiceId=$invoiceId');
      debugPrint('⚠️ Fallback: showing ALL items because invoice relation is missing.');
      for (int i = 0; i < allItems.length && i < 5; i++) {
        final it = allItems[i];
        debugPrint(
          '   • ${it.name} | itemId=${it.id} | invTarget=${it.invoiceData.target?.id} | invRaw=${(() {
            try {
              return it.invoiceDataId;
            } catch (_) {
              return null;
            }
          })()}',
        );
      }
      return allItems;
    }

    return filtered;
  }

  double _calculateTotalFromItems(List<InvoiceItemsEntity> items) {
    double total = 0.0;
    for (final item in items) {
      total += item.totalAmount ?? 0.0;
    }
    debugPrint('💰 Confirm total: ₱${total.toStringAsFixed(2)}');
    return total;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Invoice #${widget.invoiceNumber}'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No delivery data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final matchedDelivery = _findDeliveryByInvoiceId(_currentDeliveries);

    if (matchedDelivery == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Invoice not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This invoice is not linked to any delivery in this trip.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ✅ IMPORTANT: Filter items for this invoice only
    final items = _filterItemsForInvoice(matchedDelivery);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No items for this invoice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or check if invoiceItems are properly linked to this invoice.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ✅ total must be based on filtered items (per invoice)
    final total = _calculateTotalFromItems(items);

    return Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];

                    return ConfirmProductList(
                      deliveryData: matchedDelivery,
                      item: item, // ✅ NEW FORMAT
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ConfirmSummaryOrderProductBtn(
            deliveryDataId: widget.deliveryDataId,
            title: 'Total Amount',
            amount: '₱${total.toStringAsFixed(2)}',
          ),
        ),

        // ✅ show thin progress while bloc reloads
        BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
          builder: (context, state) {
            if (state is DeliveryDataLoading) {
              return const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deliverySubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
