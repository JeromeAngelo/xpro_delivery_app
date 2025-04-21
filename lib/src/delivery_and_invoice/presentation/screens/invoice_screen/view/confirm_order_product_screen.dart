import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_product_list.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_summary_order_product_btn.dart';
import 'package:intl/intl.dart';
class ConfirmOrderProductScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final List<ProductModel> products;
  final CustomerModel customer;

  const ConfirmOrderProductScreen({
    super.key,
    required this.invoice,
    required this.products,
    required this.customer,
  });

  @override
  State<ConfirmOrderProductScreen> createState() =>
      _ConfirmOrderProductScreenState();
}

class _ConfirmOrderProductScreenState extends State<ConfirmOrderProductScreen> {
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");

  double _calculateTotal(List<ProductModel> products) {
    double total = 0.0;
    debugPrint('🧮 Starting total calculation');
    
    for (var product in products) {
      if (product.isCase == true) {
        final caseTotal = (product.pricePerCase ?? 0) * (product.unloadedProductCase ?? 0);
        total += caseTotal;
        debugPrint('📦 Case calculation for ${product.name}:');
        debugPrint('   Price per case: ${product.pricePerCase}');
        debugPrint('   Unloaded cases: ${product.unloadedProductCase}');
        debugPrint('   Subtotal: $caseTotal');
      }
      if (product.isPc == true) {
        final pcTotal = (product.pricePerPc ?? 0) * (product.unloadedProductPc ?? 0);
        total += pcTotal;
        debugPrint('🔢 Piece calculation for ${product.name}:');
        debugPrint('   Price per piece: ${product.pricePerPc}');
        debugPrint('   Unloaded pieces: ${product.unloadedProductPc}');
        debugPrint('   Subtotal: $pcTotal');
      }
      if (product.isPack == true) {
        final packTotal = (product.pricePerCase ?? 0) * (product.unloadedProductPack ?? 0);
        total += packTotal;
        debugPrint('📦 Pack calculation for ${product.name}:');
        debugPrint('   Price per pack: ${product.pricePerCase}');
        debugPrint('   Unloaded packs: ${product.unloadedProductPack}');
        debugPrint('   Subtotal: $packTotal');
      }
      if (product.isBox == true) {
        final boxTotal = (product.pricePerPc ?? 0) * (product.unloadedProductBox ?? 0);
        total += boxTotal;
        debugPrint('📦 Box calculation for ${product.name}:');
        debugPrint('   Price per box: ${product.pricePerPc}');
        debugPrint('   Unloaded boxes: ${product.unloadedProductBox}');
        debugPrint('   Subtotal: $boxTotal');
      }
    }
    
    debugPrint('💰 Final total amount: $total');
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.invoiceNumber}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.products.length,
                          itemBuilder: (context, index) {
                            return ConfirmProductList(
                              product: widget.products[index],
                              onProductChanged: () {
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        BlocBuilder<ProductsBloc, ProductsState>(
                          builder: (context, state) {
                            final total = _calculateTotal(widget.products);
                            return Text(
                              '₱${currencyFormatter.format(total)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ConfirmSummaryOrderProductBtn(
                  products: widget.products,
                  customer: widget.customer,
                  invoice: widget.invoice,
                  confirmTotalAmount: _calculateTotal(widget.products),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
