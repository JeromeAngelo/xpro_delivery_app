import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';

class ProductList extends StatefulWidget {
  final ProductModel product;
  final InvoiceModel invoice;
  final CustomerModel customer;
  final VoidCallback onStatusUpdate;

  const ProductList({
    super.key,
    required this.product,
    required this.invoice,
    required this.customer,
    required this.onStatusUpdate,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController caseController = TextEditingController();
  final TextEditingController pcsController = TextEditingController();
  final TextEditingController packController = TextEditingController();
  final TextEditingController boxController = TextEditingController();
  bool showSecondaryUnits = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📦 Initializing product quantities with ordered values as default');

    if (widget.product.isCase == true) {
      widget.product.unloadedProductCase = widget.product.case_;
      caseController.text = widget.product.case_?.toString() ?? '0';
      debugPrint(
          'Case: Ordered ${widget.product.case_}, Unloaded ${widget.product.unloadedProductCase}');
    }

    if (widget.product.isPc == true) {
      widget.product.unloadedProductPc = widget.product.pcs;
      pcsController.text = widget.product.pcs?.toString() ?? '0';
      debugPrint(
          'PC: Ordered ${widget.product.pcs}, Unloaded ${widget.product.unloadedProductPc}');
    }

    if (widget.product.isPack == true) {
      widget.product.unloadedProductPack = widget.product.pack;
      packController.text = widget.product.pack?.toString() ?? '0';
      debugPrint(
          'Pack: Ordered ${widget.product.pack}, Unloaded ${widget.product.unloadedProductPack}');
    }

    if (widget.product.isBox == true) {
      widget.product.unloadedProductBox = widget.product.box;
      boxController.text = widget.product.box?.toString() ?? '0';
      debugPrint(
          'Box: Ordered ${widget.product.box}, Unloaded ${widget.product.unloadedProductBox}');
    }
  }

  Widget _buildProductHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.inventory_2,
              color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name ?? 'No Name',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                widget.product.description ?? 'No Description',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              _buildReturnReasonDropdown(), // Add this line
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityInput({
    required String unit,
    required TextEditingController controller,
    required int maxQuantity,
  }) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        bool isUnloading = false;
        if (state is CustomerLocationLoaded) {
          isUnloading = state.customer.deliveryStatus.lastOrNull?.title
                  ?.toLowerCase()
                  .trim() ==
              'unloading';
        }

        return Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                unit,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 40,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      maxQuantity.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text('Ordered', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextFormField(
                      controller: controller,
                      enabled: isUnloading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      showCursor: true,
                      onTap: () => controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        filled: !isUnloading,
                        fillColor: !isUnloading
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : null,
                      ),
                      onChanged: (value) {
                        final intValue = int.tryParse(value) ?? 0;
                        if (intValue <= maxQuantity) {
                          if (unit == 'CASE') {
                            widget.product.unloadedProductCase = intValue;
                          } else if (unit == 'PCS') {
                            widget.product.unloadedProductPc = intValue;
                          }

                          context.read<ProductsBloc>().add(
                                UpdateProductQuantitiesEvent(
                                  productId: widget.product.id!,
                                  unloadedProductCase:
                                      int.tryParse(caseController.text) ?? 0,
                                  unloadedProductPc:
                                      int.tryParse(pcsController.text) ?? 0,
                                  unloadedProductPack:
                                      int.tryParse(packController.text) ?? 0,
                                  unloadedProductBox:
                                      int.tryParse(boxController.text) ?? 0,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                  Text('Unloaded',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReturnReasonDropdown() {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        return Container(
          width: 150,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductReturnReason>(
              value: widget.product.returnReason ?? ProductReturnReason.none,
              isExpanded: true,
              isDense: true,
              items: ProductReturnReason.values.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(
                    _formatReason(reason.name),
                    style: TextStyle(
                      color: _isReturnReasonEnabled()
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.38),
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isReturnReasonEnabled()
                  ? (ProductReturnReason? newValue) {
                      if (newValue != null) {
                        setState(() {
                          widget.product.returnReason = newValue;
                        });
                        context.read<ProductsBloc>().add(
                              UpdateReturnReasonEvent(
                                productId: widget.product.id!,
                                reason: newValue,
                                returnProductCase:
                                    int.tryParse(caseController.text) ?? 0,
                                returnProductPc:
                                    int.tryParse(pcsController.text) ?? 0,
                                returnProductPack:
                                    int.tryParse(packController.text) ?? 0,
                                returnProductBox:
                                    int.tryParse(boxController.text) ?? 0,
                              ),
                            );
                      }
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  String _formatReason(String reason) {
    return reason
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  bool _isReturnReasonEnabled() {
    bool hasUnloadedChanges = false;

    if (widget.product.isCase == true) {
      final unloadedCase = int.tryParse(caseController.text) ?? 0;
      hasUnloadedChanges = unloadedCase < (widget.product.case_ ?? 0);
    }

    if (widget.product.isPc == true) {
      final unloadedPcs = int.tryParse(pcsController.text) ?? 0;
      hasUnloadedChanges =
          hasUnloadedChanges || unloadedPcs < (widget.product.pcs ?? 0);
    }

    if (widget.product.isPack == true) {
      final unloadedPack = int.tryParse(packController.text) ?? 0;
      hasUnloadedChanges =
          hasUnloadedChanges || unloadedPack < (widget.product.pack ?? 0);
    }

    if (widget.product.isBox == true) {
      final unloadedBox = int.tryParse(boxController.text) ?? 0;
      hasUnloadedChanges =
          hasUnloadedChanges || unloadedBox < (widget.product.box ?? 0);
    }

    return hasUnloadedChanges;
  }

  Widget _buildUnitsSection() {
    return Column(
      children: [
        if (widget.product.isCase == true)
          _buildQuantityInput(
            controller: caseController,
            maxQuantity: widget.product.case_ ?? 0,
            unit: widget.product.primaryUnit?.name ?? 'CASE',
          ),
        if (widget.product.isPc == true) ...[
          const SizedBox(height: 16),
          _buildQuantityInput(
            controller: pcsController,
            maxQuantity: widget.product.pcs ?? 0,
            unit: widget.product.secondaryUnit?.name ?? 'PCS',
          ),
        ],
        if (widget.product.isPack == true) ...[
          const SizedBox(height: 16),
          _buildQuantityInput(
            controller: packController,
            maxQuantity: widget.product.pack ?? 0,
            unit: 'PACK',
          ),
        ],
        if (widget.product.isBox == true) ...[
          const SizedBox(height: 16),
          _buildQuantityInput(
            controller: boxController,
            maxQuantity: widget.product.box ?? 0,
            unit: 'BOX',
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProductHeader(),
            const SizedBox(height: 20),
            _buildUnitsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    caseController.dispose();
    pcsController.dispose();
    packController.dispose();
    boxController.dispose();
    super.dispose();
  }
}
