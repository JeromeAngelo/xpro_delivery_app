import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/view/delivery_main_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/dialog_instruction.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/invoice_screen.dart';
class DeliveryAndInvoiceView extends StatefulWidget {
  final DeliveryDataEntity? selectedCustomer;

  const DeliveryAndInvoiceView({super.key, required this.selectedCustomer});

  @override
  State<DeliveryAndInvoiceView> createState() => _DeliveryAndInvoiceViewState();
}

class _DeliveryAndInvoiceViewState extends State<DeliveryAndInvoiceView> {
  int _selectedIndex = 0;
  String _deliveryNumber = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  void _loadLocalData() {
    if (widget.selectedCustomer != null) {
      debugPrint(
        '📱 DeliveryAndInvoiceView: Customer data received: ${widget.selectedCustomer!.id}',
      );

      _updateDeliveryNumber(widget.selectedCustomer!);
      debugPrint('📱 Using customer data from navigation (offline-first)');
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
    return BlocListener<DeliveryDataBloc, DeliveryDataState>(
      listener: (context, state) {
        debugPrint('🎯 DeliveryDataBloc state changed: $state');

        if (state is DeliveryDataLoaded) {
          _updateDeliveryNumber(state.deliveryData);
        } else if (state is AllDeliveryDataLoaded &&
            state.deliveryData.isNotEmpty) {
          final match = state.deliveryData.firstWhere(
            (d) => d.id == widget.selectedCustomer?.id,
            orElse: () => state.deliveryData.first,
          );
          _updateDeliveryNumber(match);
        }
      },
      child: BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
        builder: (context, state) {
          debugPrint('🎯 Building DeliveryAndInvoiceView with state: $state');
          debugPrint('🏷️ Current delivery number: $_deliveryNumber');

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/delivery-and-timeline'),
              ),
              title: Text(
                _deliveryNumber,
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
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
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
