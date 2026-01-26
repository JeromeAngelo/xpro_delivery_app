import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';

import '../../../../../../core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

class ProductList extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final InvoiceItemsEntity item; // ✅ PASS ITEM DIRECTLY
  final Function(int baseQuantity)? onBaseQuantityChanged;

  const ProductList({
    super.key,
    required this.deliveryData,
    required this.item,
    this.onBaseQuantityChanged,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late TextEditingController _baseQuantityController;
  late FocusNode _baseQuantityFocusNode;

  int _maxQuantity = 0;
  int _currentBaseQuantity = 0;

  // ✅ Direct item reference (no index, no list access)
  InvoiceItemsEntity get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
    _setupControllers();

    debugPrint('📦 ProductList init');
    debugPrint('   • Item: ${_item.name}');
    debugPrint('   • Qty: ${_item.quantity}');
    debugPrint('   • BaseQty: $_currentBaseQuantity');
    debugPrint('   • DeliveryData: ${widget.deliveryData.id}');
  }

  void _initializeQuantities() {
    _maxQuantity = (_item.quantity ?? 0).toInt();
    _currentBaseQuantity = (_item.totalBaseQuantity ?? _maxQuantity).toInt();

    if (_currentBaseQuantity > _maxQuantity) {
      _currentBaseQuantity = _maxQuantity;
    }
  }

  void _setupControllers() {
    _baseQuantityController = TextEditingController(
      text: _currentBaseQuantity.toString(),
    );
    _baseQuantityFocusNode = FocusNode();

    _baseQuantityController.addListener(_onBaseQuantityChanged);
    _baseQuantityFocusNode.addListener(_onFocusChanged);
  }

  void _onBaseQuantityChanged() {
    final text = _baseQuantityController.text;

    if (text.isEmpty) {
      _updateBaseQuantity(0);
      return;
    }

    final value = int.tryParse(text);
    if (value == null) return;

    if (value > _maxQuantity) {
      _setControllerValue(_maxQuantity);
    } else if (value < 0) {
      _setControllerValue(0);
    } else {
      _updateBaseQuantity(value);
    }
  }

  void _setControllerValue(int value) {
    _baseQuantityController.text = value.toString();
    _baseQuantityController.selection = TextSelection.fromPosition(
      TextPosition(offset: _baseQuantityController.text.length),
    );
    _updateBaseQuantity(value);
  }

  void _onFocusChanged() {
    if (!_baseQuantityFocusNode.hasFocus &&
        _baseQuantityController.text.isEmpty) {
      _setControllerValue(0);
    }
  }

  void _updateBaseQuantity(int newValue) {
    if (_currentBaseQuantity == newValue) return;

    setState(() {
      _currentBaseQuantity = newValue;
    });

    // ✅ reflect change in entity (UI consistency only)
    _item.totalBaseQuantity;

    debugPrint('📊 BaseQty updated → $_currentBaseQuantity');
    widget.onBaseQuantityChanged?.call(newValue);
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  Widget _buildProductHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.inventory_2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _item.name ?? 'No Name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              if ((_item.brand ?? '').isNotEmpty)
                Text(
                  'Brand: ${_item.brand}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if ((_item.refId ?? '').isNotEmpty)
                Text(
                  'Ref: ${_item.refId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Padding(
      padding: const EdgeInsets.only(right: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _item.uom ?? 'UOM',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          _quantityBox(_maxQuantity.toString(), 'Quantity'),
          const SizedBox(width: 24),
          _editableQuantityBox(),
        ],
      ),
    );
  }

  Widget _quantityBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _editableQuantityBox() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  _baseQuantityFocusNode.hasFocus
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _baseQuantityController,
            focusNode: _baseQuantityFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        Text(
          'Base Qty',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color:
                _baseQuantityFocusNode.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _priceColumn(
            'Unit Price',
            '₱${_item.uomPrice?.toStringAsFixed(2) ?? '0.00'}',
            Theme.of(context).colorScheme.primary,
          ),
          _priceColumn(
            'Total Amount',
            '₱${_item.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
            Theme.of(context).colorScheme.secondary,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _priceColumn(
    String label,
    String value,
    Color color, {
    bool large = false,
  }) {
    return Column(
      crossAxisAlignment:
          large ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: (large
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.titleMedium)!
              .copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(),
            const SizedBox(height: 20),
            _buildQuantitySection(),
            if (_currentBaseQuantity != _maxQuantity) _buildQuantityInfo(),
            const SizedBox(height: 16),
            _buildPriceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Delivering $_currentBaseQuantity of $_maxQuantity items',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseQuantityController.dispose();
    _baseQuantityFocusNode.dispose();
    super.dispose();
  }
}
