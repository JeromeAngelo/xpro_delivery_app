import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_btn.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

import '../../../../../../core/common/app/features/delivery_data/invoice_data/domain/entity/invoice_data_entity.dart';

class InvoiceScreen extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const InvoiceScreen({super.key, this.selectedCustomer});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;
  bool _isLoading = false;

  DeliveryDataEntity? _deliveryData; // ✅ single delivery record loaded by id

  // ✅ subscriptions (same clean pattern as other screens)
  StreamSubscription? _deliverySub;

  late final DeliveryDataBloc _deliveryDataBloc;

  @override
  void initState() {
    super.initState();

    _deliveryDataBloc = context.read<DeliveryDataBloc>();
    _setupDeliveryListener();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _setupDeliveryListener() {
    if (_isInitialized) return;

    _deliverySub = _deliveryDataBloc.stream.listen((state) {
      if (!mounted) return;

      debugPrint('📦 InvoiceScreen DeliveryDataBloc: ${state.runtimeType}');

      if (state is DeliveryDataLoading) {
        setState(() => _isLoading = true);
      }

      if (state is DeliveryDataLoaded) {
        setState(() {
          _deliveryData = state.deliveryData;
          _isLoading = false;
        });

        debugPrint('✅ InvoiceScreen: DeliveryDataLoaded');
        debugPrint('   🆔 deliveryId=${state.deliveryData.id}');
        debugPrint('   🧾 invoices=${_safeInvoicesCount(state.deliveryData)}');
        debugPrint('   📦 invoiceItems=${_safeItemsCount(state.deliveryData)}');
        debugPrint('   🔄 isUnloading=${state.deliveryData.isUnloading}');
        debugPrint('   ✅ isUnloaded=${state.deliveryData.isUnloaded}');
      }

      if (state is DeliveryDataError) {
        setState(() => _isLoading = false);
        debugPrint('❌ InvoiceScreen: DeliveryDataError: ${state.message}');
      }
    });

    _isInitialized = true;
  }

  Future<void> _loadData() async {
    final id = (widget.selectedCustomer?.id ?? '').toString().trim();
    if (id.isEmpty) {
      debugPrint('⚠️ InvoiceScreen: selectedCustomer is null or has empty id');
      return;
    }

    setState(() => _isLoading = true);

    debugPrint('🔄 InvoiceScreen: loading delivery data by id=$id');
    _deliveryDataBloc.add(GetDeliveryDataByIdEvent(id));
  }

  Future<void> _refresh() async {
    debugPrint('🔄 InvoiceScreen: manual refresh');
    await _loadData();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // -------------------------------------------------------------
  // UI helpers (no invoice bloc/status/items blocs here)
  // -------------------------------------------------------------
  int _safeInvoicesCount(DeliveryDataEntity d) {
    try {
      return d.invoices.length;
    } catch (_) {
      return 0;
    }
  }

  int _safeItemsCount(DeliveryDataEntity d) {
    try {
      return d.invoiceItems.length;
    } catch (_) {
      return 0;
    }
  }

  String _statusLine(DeliveryDataEntity d) {
    final isUnloaded = d.isUnloaded == true;
    final isUnloading = d.isUnloading == true;

    if (isUnloaded) return 'The items are unloaded';
    if (!isUnloading) return 'The delivery is ready';
    return 'Unloading in progress';
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);

    final selected = widget.selectedCustomer;
    final fallbackDelivery = selected; // if bloc not yet loaded
    final effective = _deliveryData ?? fallbackDelivery;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, effective),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeliveryDataEntity? deliveryData) {
    // ✅ no selection
    if (deliveryData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Select a customer to view invoices',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Pull to refresh once selected.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    // ✅ loading
    if (_isLoading && _deliveryData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading delivery data...'),
          ],
        ),
      );
    }

    final invoices = (() {
      try {
        return deliveryData.invoices.toList();
      } catch (_) {
        return <dynamic>[];
      }
    })();

    final productsCount = _safeItemsCount(deliveryData);
    final statusText = _statusLine(deliveryData);

    debugPrint('🎯 InvoiceScreen UI');
    debugPrint('   🆔 deliveryId=${deliveryData.id}');
    debugPrint('   🧾 invoices=${invoices.length}');
    debugPrint('   📦 invoiceItems=$productsCount');
    debugPrint('   🏷️ status="$statusText"');

    // ✅ error state is shown only when bloc says so AND we don't have cached deliveryData
    // (kept clean: we still show basic data from navigation if present)
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            if (state is DeliveryDataError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
      child: Column(
        children: [
          // ✅ Top summary / status banner (pro-looking)
          

          // ✅ Invoice list
          Expanded(
            child: invoices.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No invoices available',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'This delivery has no associated invoices',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final inv = invoices[index];

                      // ✅ safest label
                      final invLabel =
                          (inv.refId ?? inv.name ?? inv.id ?? 'Unknown')
                              .toString()
                              .trim();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: CommonListTiles(
                          title: 'Invoice #$invLabel',
                          subtitle: '$productsCount Products | $statusText',
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Icon(
                              Icons.receipt_long,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onTap: () {
                            final invoiceId = (inv.id ?? '').toString().trim();
                            if (invoiceId.isEmpty) return;

                            final route =
                                '/product-list/$invoiceId/${inv.refId ?? inv.name}';

                            debugPrint('➡️ InvoiceScreen: open $route');
                            context.push(route, extra: deliveryData);
                          },
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        ),
                      );
                    },
                  ),
          ),

          // ✅ Bottom confirm button stays (uses delivery data entity)
          Padding(
            padding: const EdgeInsets.all(10),
            child: ConfirmBtn(
              invoices: invoices.cast<InvoiceDataEntity>(),
              customer: deliveryData,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deliverySub?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
