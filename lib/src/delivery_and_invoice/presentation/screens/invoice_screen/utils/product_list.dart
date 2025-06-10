import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';

class ProductList extends StatefulWidget {
  final InvoiceItemsEntity invoiceItem;
  final Function(int baseQuantity)? onBaseQuantityChanged;

  const ProductList({
    super.key,
    required this.invoiceItem,
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

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
    _setupControllers();

    debugPrint('📦 Initializing invoice item: ${widget.invoiceItem.name}');
    debugPrint('   📊 Quantity: ${widget.invoiceItem.quantity}');
    debugPrint('   📊 Base Quantity: $_currentBaseQuantity');
    debugPrint('   💰 Unit Price: ${widget.invoiceItem.uomPrice}');
    debugPrint('   💵 Total Amount: ${widget.invoiceItem.totalAmount}');
    debugPrint(
      '   🔗 Delivery Data ID: ${widget.invoiceItem.invoiceData.target?.id}',
    );
  }

  void _initializeQuantities() {
    _maxQuantity = (widget.invoiceItem.quantity ?? 0).toInt();
    _currentBaseQuantity =
        (widget.invoiceItem.totalBaseQuantity ?? _maxQuantity).toInt();

    // Ensure base quantity doesn't exceed max quantity
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
      // Consider empty as 0
      _updateBaseQuantity(0);
      return;
    }

    final value = int.tryParse(text);
    if (value != null) {
      // Restrict to max quantity
      if (value > _maxQuantity) {
        _baseQuantityController.text = _maxQuantity.toString();
        _baseQuantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: _baseQuantityController.text.length),
        );
        _updateBaseQuantity(_maxQuantity);
      } else if (value < 0) {
        _baseQuantityController.text = '0';
        _baseQuantityController.selection = TextSelection.fromPosition(
          TextPosition(offset: _baseQuantityController.text.length),
        );
        _updateBaseQuantity(0);
      } else {
        _updateBaseQuantity(value);
      }
    }
  }

  void _onFocusChanged() {
    if (!_baseQuantityFocusNode.hasFocus) {
      // When focus is lost, ensure we have a valid value
      if (_baseQuantityController.text.isEmpty) {
        _baseQuantityController.text = '0';
        _updateBaseQuantity(0);
      }
    }
  }

  void _updateBaseQuantity(int newValue) {
    if (_currentBaseQuantity != newValue) {
      setState(() {
        _currentBaseQuantity = newValue;
      });

      debugPrint('📊 Base quantity updated: $newValue (max: $_maxQuantity)');
      widget.onBaseQuantityChanged?.call(newValue);
    }
  }

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
                widget.invoiceItem.name ?? 'No Name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              if (widget.invoiceItem.brand != null &&
                  widget.invoiceItem.brand!.isNotEmpty)
                Text(
                  'Brand: ${widget.invoiceItem.brand}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (widget.invoiceItem.refId != null &&
                  widget.invoiceItem.refId!.isNotEmpty)
                Text(
                  'Ref: ${widget.invoiceItem.refId}',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            widget.invoiceItem.uom ?? 'UOM',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 80,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _maxQuantity.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('Quantity', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 24),
          Column(
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
                    width: _baseQuantityFocusNode.hasFocus ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _baseQuantityController,
                  focusNode: _baseQuantityFocusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3), // Reasonable limit
                  ],
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    isDense: true,
                  ),
                  onTap: () {
                    // Select all text when user taps the field
                    _baseQuantityController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _baseQuantityController.text.length,
                    );
                  },
                  onSubmitted: (value) {
                    _baseQuantityFocusNode.unfocus();
                  },
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
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit Price', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '₱${widget.invoiceItem.uomPrice?.toStringAsFixed(2) ?? '0.00'}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '₱${widget.invoiceItem.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInfo() {
    if (_currentBaseQuantity != _maxQuantity) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Delivering $_currentBaseQuantity of $_maxQuantity items',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
            _buildQuantitySection(),
            _buildQuantityInfo(),
            const SizedBox(height: 16),
            _buildPriceSection(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseQuantityController.removeListener(_onBaseQuantityChanged);
    _baseQuantityFocusNode.removeListener(_onFocusChanged);
    _baseQuantityController.dispose();
    _baseQuantityFocusNode.dispose();
    super.dispose();
  }
}
