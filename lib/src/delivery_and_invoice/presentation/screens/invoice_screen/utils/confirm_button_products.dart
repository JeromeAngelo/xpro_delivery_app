import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';

class ConfirmButtonProducts extends StatefulWidget {
  final int checkedProducts;
  final int totalProducts;
  final String invoiceId;
  final CustomerEntity customer;
  final invoice;
  final List<ProductModel> products;
  final Map<String, Map<String, TextEditingController>> productControllers;

  const ConfirmButtonProducts({
    super.key,
    required this.checkedProducts,
    required this.totalProducts,
    required this.invoiceId,
    required this.customer,
    required this.invoice,
    required this.products,
    required this.productControllers,
  });

  @override
  State<ConfirmButtonProducts> createState() => _ConfirmButtonProductsState();
}

class _ConfirmButtonProductsState extends State<ConfirmButtonProducts> {
  bool isLoading = false;
bool get canConfirm {
  final customerState = context.read<CustomerBloc>().state;
  if (customerState is CustomerLocationLoaded) {
    debugPrint('🔍 Checking customer delivery status');
    
    // Get latest delivery status directly from customer
    final latestStatus = customerState.customer.deliveryStatus
        .lastOrNull?.title?.toLowerCase().trim();
        
    debugPrint('📊 Current status: $latestStatus');
    
    // Enable button when status is unloading, regardless of product changes
    return latestStatus == 'unloading';
  }
  return false;
}



  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductsBloc, ProductsState>(
      listener: (context, state) {
        if (state is ProductStatusUpdated) {
          setState(() {
            isLoading = true;
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            setState(() {
              isLoading = false;
            });
            context.read<InvoiceBloc>().add(const GetInvoiceEvent());
          });
        }
      },
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: isLoading
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              : RoundedButton(
                  label: 'Order Summary',
                  onPressed: canConfirm
                      ? () {
                          // Confirm delivery
                          // context.read<ProductsBloc>().add(
                          //       ConfirmDeliveryProductsEvent(widget.invoiceId),
                          //     );

                          // Navigate to confirmation screen
                          context.push(
                            '/confirm-order/${widget.invoiceId}',
                            extra: {
                              'invoice': widget.invoice,
                              'products': widget.products.map((product) {
                                debugPrint('🚀 Passing updated product data:');
                                debugPrint('ID: ${product.id}');
                                debugPrint(
                                    'Modified Case: ${product.unloadedProductCase}');
                                debugPrint(
                                    'Modified PC: ${product.unloadedProductPc}');
                                return product;
                              }).toList(),
                              'customer': widget.customer,
                            },
                          );
                        }
                      : (() {}), // Add empty callback instead of null
                  buttonColour: canConfirm
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.errorContainer,
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                )),
    );
  }
}
