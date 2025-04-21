// ignore_for_file: unused_element

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';

class ConfirmProductList extends StatefulWidget {
  final ProductModel product;
  final Function() onProductChanged;

  const ConfirmProductList({
    super.key,
    required this.product,
    required this.onProductChanged,
  });

  @override
  State<ConfirmProductList> createState() => _ConfirmProductListState();
}

class _ConfirmProductListState extends State<ConfirmProductList> {
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");
  bool isEditing = false;
  final TextEditingController caseController = TextEditingController();
  final TextEditingController pcsController = TextEditingController();
  final TextEditingController packController = TextEditingController();
  final TextEditingController boxController = TextEditingController();
  @override
  @override
  void initState() {
    super.initState();
    debugPrint('🔄 Initializing confirmation view with modified values:');
    debugPrint('Product ID: ${widget.product.id}');
    debugPrint('Modified Case: ${widget.product.unloadedProductCase}');
    debugPrint('Modified PC: ${widget.product.unloadedProductPc}');
    debugPrint('Modified Pack: ${widget.product.unloadedProductPack}');
    debugPrint('Modified Box: ${widget.product.unloadedProductBox}');

    final productState = context.read<ProductsBloc>().state;
    if (productState is ProductQuantitiesUpdated &&
        productState.productId == widget.product.id) {
      widget.product.unloadedProductCase = productState.unloadedProductCase;
      widget.product.unloadedProductPc = productState.unloadedProductPc;
      widget.product.unloadedProductPack = productState.unloadedProductPack;
      widget.product.unloadedProductBox = productState.unloadedProductBox;
    }

    caseController.text = widget.product.unloadedProductCase?.toString() ??
        widget.product.case_.toString();
    pcsController.text = widget.product.unloadedProductPc?.toString() ??
        widget.product.pcs.toString();
    packController.text = widget.product.unloadedProductPack?.toString() ??
        widget.product.pack.toString();
    boxController.text = widget.product.unloadedProductBox?.toString() ??
        widget.product.box.toString();
  }

  Widget _buildEditModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(isEditMode: true),
        const SizedBox(height: 10),
        _buildReturnReasonDropdown(),
        const SizedBox(height: 20),
        if (widget.product.isCase == true)
          _buildQuantityRow(
            'CASE',
            widget.product.case_ ?? 0,
            caseController
              ..text = widget.product.unloadedProductCase?.toString() ??
                  widget.product.case_?.toString() ??
                  '0',
            (value) {
              final intValue = int.tryParse(value) ?? 0;
              if (intValue <= (widget.product.case_ ?? 0)) {
                setState(() {
                  widget.product.unloadedProductCase = intValue;
                });
              }
            },
          ),
        if (widget.product.isPc == true) ...[
          const SizedBox(height: 20),
          _buildQuantityRow(
            'PCS',
            widget.product.pcs ?? 0,
            pcsController
              ..text = widget.product.unloadedProductPc?.toString() ??
                  widget.product.pcs?.toString() ??
                  '0',
            (value) {
              final intValue = int.tryParse(value) ?? 0;
              if (intValue <= (widget.product.pcs ?? 0)) {
                setState(() {
                  widget.product.unloadedProductPc = intValue;
                });
              }
            },
          ),
        ],
        if (widget.product.isPack == true) ...[
          const SizedBox(height: 20),
          _buildQuantityRow(
            'PACK',
            widget.product.pack ?? 0,
            packController
              ..text = widget.product.unloadedProductPack?.toString() ??
                  widget.product.pack?.toString() ??
                  '0',
            (value) {
              final intValue = int.tryParse(value) ?? 0;
              if (intValue <= (widget.product.pack ?? 0)) {
                setState(() {
                  widget.product.unloadedProductPack = intValue;
                });
              }
            },
          ),
        ],
        if (widget.product.isBox == true) ...[
          const SizedBox(height: 20),
          _buildQuantityRow(
            'BOX',
            widget.product.box ?? 0,
            boxController
              ..text = widget.product.unloadedProductBox?.toString() ??
                  widget.product.box?.toString() ??
                  '0',
            (value) {
              final intValue = int.tryParse(value) ?? 0;
              if (intValue <= (widget.product.box ?? 0)) {
                setState(() {
                  widget.product.unloadedProductBox = intValue;
                });
              }
            },
          ),
        ],
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _calculateReturnsText(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => isEditing = false);
                widget.onProductChanged();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityRow(
    String unit,
    int maxQuantity,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
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
                ),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 0;
                  if (intValue <= maxQuantity) {
                    onChanged(value);
                  } else {
                    controller.text = maxQuantity.toString();
                    onChanged(maxQuantity.toString());
                  }
                },
              ),
            ),
            Text('Received', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildReturnReasonDropdown() {
  bool hasReturns = _calculateCaseReturns() > 0 || 
                    _calculatePcsReturns() > 0 || 
                    _calculatePackReturns() > 0 || 
                    _calculateBoxReturns() > 0;

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
                color: hasReturns 
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
              ),
            ),
          );
        }).toList(),
        onChanged: hasReturns ? (ProductReturnReason? newValue) {
          if (newValue != null) {
            setState(() {
              widget.product.returnReason = newValue;
            });
            context.read<ProductsBloc>().add(
              UpdateReturnReasonEvent(
                productId: widget.product.id!,
                reason: newValue,
                returnProductCase: _calculateCaseReturns(),
                returnProductPc: _calculatePcsReturns(),
                returnProductPack: _calculatePackReturns(),
                returnProductBox: _calculateBoxReturns(),
              ),
            );
          }
        } : null,
      ),
    ),
  );
}


  Widget _buildQuantityInputs({
    required String unit,
    required String totalQuantity,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUnitLabel(unit),
        const SizedBox(width: 10),
        _buildQuantityDisplay(totalQuantity, 'Ordered'),
        const SizedBox(width: 8),
        _buildQuantityInput(
          controller: controller,
          onChanged: onChanged,
          maxQuantity: int.parse(totalQuantity),
        ),
      ],
    );
  }

  Widget _buildUnitLabel(String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        unit,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantityDisplay(String quantity, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            quantity,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildQuantityInput({
    required TextEditingController controller,
    required Function(String) onChanged,
    required int maxQuantity,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 40,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            onChanged: (value) {
              final intValue = int.tryParse(value) ?? 0;
              if (intValue <= maxQuantity) {
                onChanged(value);
              } else {
                controller.text = maxQuantity.toString();
                onChanged(maxQuantity.toString());
              }
            },
          ),
        ),
        Text('Received', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCaseQuantityInputs() {
    return _buildQuantityInputs(
      unit: widget.product.primaryUnit?.name ?? 'CASE',
      totalQuantity: widget.product.case_?.toString() ?? '0',
      controller: caseController,
      onChanged: (value) {
        context.read<ProductsBloc>().add(
              UpdateProductQuantitiesEvent(
                productId: widget.product.id!,
                unloadedProductCase: int.tryParse(value) ?? 0,
                unloadedProductPc: widget.product.unloadedProductPc ?? 0,
                unloadedProductPack: widget.product.unloadedProductPack ?? 0,
                unloadedProductBox: widget.product.unloadedProductBox ?? 0,
              ),
            );
      },
    );
  }

  Widget _buildPcsQuantityInputs() {
    return _buildQuantityInputs(
      unit: widget.product.secondaryUnit?.name ?? 'PCS',
      totalQuantity: widget.product.pcs?.toString() ?? '0',
      controller: pcsController,
      onChanged: (value) {
        context.read<ProductsBloc>().add(
              UpdateProductQuantitiesEvent(
                productId: widget.product.id!,
                unloadedProductCase: widget.product.unloadedProductCase ?? 0,
                unloadedProductPc: int.tryParse(value) ?? 0,
                unloadedProductPack: widget.product.unloadedProductPack ?? 0,
                unloadedProductBox: widget.product.unloadedProductBox ?? 0,
              ),
            );
      },
    );
  }

  Widget _buildPackQuantityInputs() {
    return _buildQuantityInputs(
      unit: 'PACK',
      totalQuantity: widget.product.pcs?.toString() ?? '0',
      controller: packController,
      onChanged: (value) {
        context.read<ProductsBloc>().add(
              UpdateProductQuantitiesEvent(
                productId: widget.product.id!,
                unloadedProductCase: widget.product.unloadedProductCase ?? 0,
                unloadedProductPc: widget.product.unloadedProductPc ?? 0,
                unloadedProductPack: int.tryParse(value) ?? 0,
                unloadedProductBox: widget.product.unloadedProductBox ?? 0,
              ),
            );
      },
    );
  }

  Widget _buildBoxQuantityInputs() {
    return _buildQuantityInputs(
      unit: 'BOX',
      totalQuantity: widget.product.pcs?.toString() ?? '0',
      controller: boxController,
      onChanged: (value) {
        context.read<ProductsBloc>().add(
              UpdateProductQuantitiesEvent(
                productId: widget.product.id!,
                unloadedProductCase: widget.product.unloadedProductCase ?? 0,
                unloadedProductPc: widget.product.unloadedProductPc ?? 0,
                unloadedProductPack: widget.product.unloadedProductPack ?? 0,
                unloadedProductBox: int.tryParse(value) ?? 0,
              ),
            );
      },
    );
  }

  Widget _buildViewModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductHeader(isEditMode: false),
        const SizedBox(height: 8),
        _buildQuantityInfo(),
        const Divider(),
        _buildTotalAmount(),
      ],
    );
  }

  Widget _buildProductHeader({required bool isEditMode}) {
    return Row(
      children: [
        if (isEditMode)
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
                widget.product.description ?? 'No description',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (!isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => isEditing = true),
          ),
      ],
    );
  }

  Widget _buildQuantityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.isCase == true)
          _buildUnitQuantityInfo(
            'CASE',
            widget.product.case_ ?? 0,
            widget.product.unloadedProductCase ?? 0,
          ),
        if (widget.product.isPc == true)
          _buildUnitQuantityInfo(
            'PCS',
            widget.product.pcs ?? 0,
            widget.product.unloadedProductPc ?? 0,
          ),
        if (widget.product.isPack == true)
          _buildUnitQuantityInfo(
            'PACK',
            widget.product.pack ?? 0,
            widget.product.unloadedProductPack ?? 0,
          ),
        if (widget.product.isBox == true)
          _buildUnitQuantityInfo(
            'BOX',
            widget.product.box ?? 0,
            widget.product.unloadedProductBox ?? 0,
          ),
      ],
    );
  }

  Widget _buildUnitQuantityInfo(String unit, int ordered, int received) {
    // If no updates were made, received should equal ordered
    final actualReceived = received == 0 ? ordered : received;
    final returns = ordered - actualReceived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$unit: Ordered $ordered, Received $actualReceived'),
        if (returns > 0)
          Text(
            'Returns: $returns ${widget.product.returnReason?.name ?? ""}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Amount:'),
        Text(
          ' ₱${_calculateTotalAmount()}',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _calculateTotalAmount() {
    double totalAmount = 0.0;

    if (widget.product.isCase == true) {
      totalAmount += (widget.product.unloadedProductCase ?? 0) *
          (widget.product.pricePerCase ?? 0.0);
    }

    if (widget.product.isPc == true) {
      totalAmount += (widget.product.unloadedProductPc ?? 0) *
          (widget.product.pricePerPc ?? 0.0);
    }

    return currencyFormatter.format(totalAmount);
  }

  int _calculateCaseReturns() {
    return (widget.product.case_ ?? 0) -
        (widget.product.unloadedProductCase ?? 0);
  }

  int _calculatePcsReturns() {
    return (widget.product.pcs ?? 0) - (widget.product.unloadedProductPc ?? 0);
  }

  int _calculatePackReturns() {
    return (widget.product.pack ?? 0) -
        (widget.product.unloadedProductPack ?? 0);
  }

  int _calculateBoxReturns() {
    return (widget.product.box ?? 0) - (widget.product.unloadedProductBox ?? 0);
  }

  String _calculateReturnsText() {
    List<String> returns = [];

    if (widget.product.isCase == true) {
      final caseReturns = _calculateCaseReturns();
      if (caseReturns > 0) returns.add('$caseReturns cases');
    }

    if (widget.product.isPc == true) {
      final pcsReturns = _calculatePcsReturns();
      if (pcsReturns > 0) returns.add('$pcsReturns pcs');
    }

    if (widget.product.isPack == true) {
      final packReturns = _calculatePackReturns();
      if (packReturns > 0) returns.add('$packReturns pack');
    }

    if (widget.product.isBox == true) {
      final boxReturns = _calculateBoxReturns();
      if (boxReturns > 0) returns.add('$boxReturns box');
    }

    return returns.join(', ');
  }

  bool _isReturnReasonEnabled() {
    return _calculateCaseReturns() > 0 ||
        _calculatePcsReturns() > 0 ||
        _calculatePackReturns() > 0 ||
        _calculateBoxReturns() > 0;
  }

  String _formatReason(String reason) {
    return reason
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isEditing ? _buildEditModeContent() : _buildViewModeContent(),
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
