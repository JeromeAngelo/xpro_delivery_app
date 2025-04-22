import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';

class ConfirmSummaryOrderProductBtn extends StatelessWidget {
  final List<ProductModel> products;
  final InvoiceModel invoice;
  final CustomerModel customer;
  final double confirmTotalAmount;

  const ConfirmSummaryOrderProductBtn({
    super.key,
    required this.products,
    required this.invoice,
    required this.customer,
    required this.confirmTotalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return RoundedButton(
      label: 'Confirm Order Summary',
      onPressed: () {
        debugPrint('🔄 Starting confirmation process');
        debugPrint('💰 Total Amount to record: $confirmTotalAmount');

        // Record total amount and update invoice status
        context.read<ProductsBloc>().add(
          ConfirmDeliveryProductsEvent(
            invoiceId: invoice.id ?? '',
            confirmTotalAmount: confirmTotalAmount,
            customerId: customer.id ?? '',
          ),
        );

        // Process returns if any
        for (var product in products) {
          if (product.isCase == true) {
            final returnCaseQty =
                (product.case_ ?? 0) - (product.unloadedProductCase ?? 0);
            if (returnCaseQty > 0 ||
                product.returnReason != ProductReturnReason.none) {
              _processProductReturn(context, product);
            }
          }
        }

        // Navigate back to delivery screen
        context.pushReplacement(
          '/delivery-and-invoice/${customer.id}',
          extra: customer,
        );

        // Refresh customer data
        context.read<CustomerBloc>().add(
          GetCustomerLocationEvent(customer.id ?? ''),
        );
        context.read<InvoiceBloc>().add(const GetInvoiceEvent());
        context.read<ProductsBloc>().add(const GetProductsEvent());
      },
    );
  }

  void _processProductReturn(BuildContext context, ProductModel product) {
    debugPrint('📦 Processing return for product: ${product.name}');
    debugPrint('   - Total Cases: ${product.case_}');
    debugPrint('   - Unloaded Cases: ${product.unloadedProductCase}');
    debugPrint('   - Return Reason: ${product.returnReason}');

    context.read<ProductsBloc>().add(
      AddToReturnEvent(
        productId: product.id!,
        reason: product.returnReason ?? ProductReturnReason.none,
        returnProductCase:
            (product.case_ ?? 0) - (product.unloadedProductCase ?? 0),
        returnProductPc: (product.pcs ?? 0) - (product.unloadedProductPc ?? 0),
        returnProductPack:
            (product.pack ?? 0) - (product.unloadedProductPack ?? 0),
        returnProductBox:
            (product.box ?? 0) - (product.unloadedProductBox ?? 0),
      ),
    );
  }
}
