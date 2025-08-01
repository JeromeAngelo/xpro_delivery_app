import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/view/delivery_main_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/dialog_instruction.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/invoice_screen.dart';

class DeliveryAndInvoiceView extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const DeliveryAndInvoiceView({super.key, required this.selectedCustomer});

  @override
  State<DeliveryAndInvoiceView> createState() => _DeliveryAndInvoiceViewState();
}

class _DeliveryAndInvoiceViewState extends State<DeliveryAndInvoiceView> 
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _deliveryNumber = 'Loading...';
  DeliveryDataState? _cachedState;
  bool _hasInitialized = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocalData();
    _hasInitialized = true;
    _lastRefreshTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - refresh data
      debugPrint('📱 App resumed - refreshing delivery data');
      _forceRefreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only refresh if we've already initialized and the route is current
    if (_hasInitialized) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.isActive) {
        debugPrint('🔄 Screen became active, refreshing data...');
        _refreshData();
      }
    }
  }

  void _refreshData() {
    if (widget.selectedCustomer != null) {
      debugPrint(
        '🔄 Refreshing delivery and invoice data for customer: ${widget.selectedCustomer!.id}',
      );

      final customerBloc = context.read<DeliveryDataBloc>();

      // 📱 OFFLINE-FIRST: Load local data immediately
      customerBloc.add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));

      // 🌐 Then sync remote data if online
      final connectivity = context.read<ConnectivityProvider>();
      if (connectivity.isOnline) {
        debugPrint('🌐 Online: Syncing fresh delivery and invoice data');
        customerBloc.add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));
      } else {
        debugPrint('📱 Offline: Using cached delivery and invoice data only');
      }
    }
  }

  void _forceRefreshData() {
    if (widget.selectedCustomer != null) {
      debugPrint(
        '🔄 Force refreshing delivery and invoice data for customer: ${widget.selectedCustomer!.id}',
      );

      final customerBloc = context.read<DeliveryDataBloc>();
      final connectivity = context.read<ConnectivityProvider>();

      // Force refresh from remote if online, otherwise use local
      if (connectivity.isOnline) {
        debugPrint('🌐 Force refresh: Loading fresh data from remote');
        customerBloc.add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));
      } else {
        debugPrint('📱 Force refresh: Offline, loading latest cached data');
        customerBloc.add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));
      }

      _lastRefreshTime = DateTime.now();
    }
  }

  void _loadLocalData() {
    if (widget.selectedCustomer != null) {
      debugPrint(
        '📱 Loading local data for customer: ${widget.selectedCustomer!.id}',
      );

      // Set initial delivery number if available
      _updateDeliveryNumber(widget.selectedCustomer!);

      final customerBloc = context.read<DeliveryDataBloc>();
      
      // 📱 OFFLINE-FIRST: Load local data immediately for instant UI
      customerBloc.add(GetLocalDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));
      
      // 🌐 Then sync remote data if online
      final connectivity = context.read<ConnectivityProvider>();
      if (connectivity.isOnline) {
        debugPrint('🌐 Online: Loading fresh delivery and invoice data');
        customerBloc.add(GetDeliveryDataByIdEvent(widget.selectedCustomer!.id ?? ''));
      } else {
        debugPrint('📱 Offline: Using cached data only');
      }
    }
  }

  void _updateDeliveryNumber(DeliveryDataEntity deliveryData) {
    setState(() {
      _deliveryNumber =
          deliveryData.deliveryNumber ??
          deliveryData.customer.target?.name ??
          'Unknown Delivery';
    });

    debugPrint('🏷️ Delivery number updated: $_deliveryNumber');
    debugPrint('   📦 Delivery Data ID: ${deliveryData.id}');
    debugPrint('   🔢 Delivery Number: ${deliveryData.deliveryNumber}');
    debugPrint('   👤 Customer Name: ${deliveryData.customer.target?.name}');
  }

  late final List<Widget> _screens = [
    DeliveryMainScreen(selectedCustomer: widget.selectedCustomer),
    InvoiceScreen(selectedCustomer: widget.selectedCustomer),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryDataBloc, DeliveryDataState>(
          listener: (context, state) {
            debugPrint('🎯 DeliveryDataBloc state changed: $state');

            if (state is DeliveryDataLoaded) {
              setState(() => _cachedState = state);
              _updateDeliveryNumber(state.deliveryData);
            } else if (state is AllDeliveryDataLoaded &&
                state.deliveryData.isNotEmpty) {
              // Find the matching delivery data
              final matchingDelivery = state.deliveryData.firstWhere(
                (delivery) => delivery.id == widget.selectedCustomer?.id,
                orElse: () => state.deliveryData.first,
              );
              setState(() => _cachedState = state);
              _updateDeliveryNumber(matchingDelivery);
            }
          },
        ),
      ],
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          debugPrint('🎯 Building DeliveryAndInvoiceView with state: $state');
          debugPrint('🏷️ Current delivery number: $_deliveryNumber');

          // Use cached state if available for better UX
          final effectiveState =
              (state is DeliveryDataLoaded || state is AllDeliveryDataLoaded)
                  ? state
                  : _cachedState;

          // Extract delivery number from current state
          String displayDeliveryNumber = _deliveryNumber;

          if (effectiveState is DeliveryDataLoaded) {
            displayDeliveryNumber =
                effectiveState.deliveryData.deliveryNumber ??
                effectiveState.deliveryData.customer.target?.name ??
                'Unknown Delivery';
          } else if (effectiveState is AllDeliveryDataLoaded &&
              effectiveState.deliveryData.isNotEmpty) {
            final matchingDelivery = effectiveState.deliveryData.firstWhere(
              (delivery) => delivery.id == widget.selectedCustomer?.id,
              orElse: () => effectiveState.deliveryData.first,
            );
            displayDeliveryNumber =
                matchingDelivery.deliveryNumber ??
                matchingDelivery.customer.target?.name ??
                'Unknown Delivery';
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/delivery-and-timeline'),
              ),
              title: Text(
                displayDeliveryNumber,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DeliveryInstructionsDialog(),
                    );
                  },
                ),
              ],
            ),
            body: IndexedStack(index: _selectedIndex, children: _screens),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping),
                  label: 'Deliveries',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt),
                  label: 'Invoices',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
