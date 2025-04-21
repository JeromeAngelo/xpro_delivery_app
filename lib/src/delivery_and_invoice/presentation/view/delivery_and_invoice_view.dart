
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/view/delivery_main_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/dialog_instruction.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/invoice_screen.dart';
class DeliveryAndInvoiceView extends StatefulWidget {
  final CustomerEntity? selectedCustomer;

  const DeliveryAndInvoiceView({
    super.key,
    required this.selectedCustomer,
  });

  @override
  State<DeliveryAndInvoiceView> createState() => _DeliveryAndInvoiceViewState();
}

class _DeliveryAndInvoiceViewState extends State<DeliveryAndInvoiceView> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  void _loadLocalData() {
    if (widget.selectedCustomer != null) {
      debugPrint('📱 Loading local data for customer: ${widget.selectedCustomer!.id}');
      
      final customerBloc = context.read<CustomerBloc>();
      customerBloc.add(LoadLocalCustomerLocationEvent(widget.selectedCustomer!.id ?? ''));

      final invoiceBloc = context.read<InvoiceBloc>();
      invoiceBloc.add(const LoadLocalInvoiceEvent());
    }
  }

  late final List<Widget> _screens = [
    DeliveryMainScreen(selectedCustomer: widget.selectedCustomer),
    InvoiceScreen(selectedCustomer: widget.selectedCustomer),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        String deliveryNumber = '';

        if (state is CustomerLocationLoaded) {
          deliveryNumber = state.customer.deliveryNumber ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/delivery-and-timeline'),
            ),
            title: Text(
              deliveryNumber,
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
    );
  }
}
