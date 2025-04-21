import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/confirm_button_products.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/utils/product_list.dart';

class ProductListScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final CustomerEntity customer;

  const ProductListScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customer,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}
class _ProductListScreenState extends State<ProductListScreen> with AutomaticKeepAliveClientMixin {
  final Map<String, Map<String, TextEditingController>> productControllers = {};
  bool _isDataInitialized = false;
  ProductsState? _cachedState;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_isDataInitialized) {
      debugPrint('🔄 Loading initial data');
      // Load local customer location
      context.read<CustomerBloc>().add(
        LoadLocalCustomerLocationEvent(widget.customer.id!)
      );
      // Load local products
      context.read<ProductsBloc>().add(
        LoadLocalProductsByInvoiceIdEvent(widget.invoiceId)
      );
      _isDataInitialized = true;
    }
  }

  void _refreshData() {
    debugPrint('🔄 Refreshing data');
    context.read<CustomerBloc>().add(
      GetCustomerLocationEvent(widget.customer.id!)
    );
    context.read<ProductsBloc>().add(
      GetProductsByInvoiceIdEvent(widget.invoiceId)
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoiceNumber}'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<CustomerBloc, CustomerState>(
              listener: (context, state) {
                debugPrint('📍 Customer state updated');
                if (state is CustomerLocationLoaded) {
                  final status = state.customer.deliveryStatus.lastOrNull?.title;
                  debugPrint('🔄 Current delivery status: $status');
                }
              },
            ),
            BlocListener<ProductsBloc, ProductsState>(
              listener: (context, state) {
                if (state is InvoiceProductsLoaded) {
                  setState(() {
                    _cachedState = state;
                  });
                }
              },
            ),
          ],
          child: BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              if (state is ProductsLoading && _cachedState == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final effectiveState = (state is InvoiceProductsLoaded) 
                  ? state 
                  : (_cachedState as InvoiceProductsLoaded?);

              if (effectiveState != null && 
                  effectiveState.invoiceId == widget.invoiceId) {
                debugPrint('📦 Displaying ${effectiveState.products.length} products');

                final products = effectiveState.products.map((p) {
                  final product = p as ProductModel;

                  // Initialize controllers if needed
                  if (!productControllers.containsKey(product.id)) {
                    productControllers[product.id!] = {
                      'case': TextEditingController(
                        text: product.unloadedProductCase?.toString() ?? 
                              product.case_?.toString()
                      ),
                      'pcs': TextEditingController(
                        text: product.unloadedProductPc?.toString() ?? 
                              product.pcs?.toString()
                      ),
                      'pack': TextEditingController(
                        text: product.unloadedProductPack?.toString() ?? 
                              product.pack?.toString()
                      ),
                      'box': TextEditingController(
                        text: product.unloadedProductBox?.toString() ?? 
                              product.box?.toString()
                      ),
                    };
                  }
                  return product;
                }).toList();

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductList(
                            key: ValueKey(product.id),
                            customer: widget.customer as CustomerModel,
                            product: product,
                            invoice: InvoiceModel(
                              id: widget.invoiceId,
                              invoiceNumber: widget.invoiceNumber,
                              productsList: products,
                            ),
                            onStatusUpdate: () {
                              setState(() {
                                product.status = ProductsStatus.completed;
                              });
                              _refreshData();
                            },
                          );
                        },
                      ),
                    ),
                    BlocBuilder<CustomerBloc, CustomerState>(
                      builder: (context, customerState) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: ConfirmButtonProducts(
                            checkedProducts: products.where((product) => 
                                product.status == ProductsStatus.completed).length,
                            totalProducts: products.length,
                            invoiceId: widget.invoiceId,
                            customer: widget.customer,
                            invoice: InvoiceModel(
                              id: widget.invoiceId,
                              invoiceNumber: widget.invoiceNumber,
                              productsList: products,
                            ),
                            products: products,
                            productControllers: productControllers,
                          ),
                        );
                      },
                    ),
                  ],
                );
              }

              return const Center(
                child: Text('No products available for this invoice')
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controllers in productControllers.values) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
