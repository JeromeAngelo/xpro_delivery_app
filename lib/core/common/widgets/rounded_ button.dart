import 'package:flutter/material.dart';

class RoundedButton extends StatefulWidget {
  const RoundedButton({
    required this.label,
    required this.onPressed,
    this.buttonColour,
    this.labelColour,
    this.icon,
    this.dropdownItems,
    this.onDropdownSelected,
    this.onDropdownChanged,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? buttonColour;
  final Color? labelColour;
  final Icon? icon;
  final bool isLoading;

  final List<DropdownItem>? dropdownItems;
  final Function(DropdownItem)? onDropdownSelected;
  final Function(DropdownItem?)? onDropdownChanged;

  @override
  State<RoundedButton> createState() => _RoundedButtonState();
}

class _RoundedButtonState extends State<RoundedButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return widget.dropdownItems != null
        ? _buildDropdownButton(context)
        : _buildRegularButton(context);
  }

  Widget _buildRegularButton(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading || _isProcessing;
    
    return ElevatedButton(
      style: _buttonStyle(context, isDisabled),
      onPressed: isDisabled ? null : _handlePress,
      child: _buildButtonContent(),
    );
  }

  void _handlePress() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildDropdownButton(BuildContext context) {
    return PopupMenuButton<DropdownItem>(
      offset: const Offset(0, 50),
      position: PopupMenuPosition.under,
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      itemBuilder: (BuildContext context) {
        return widget.dropdownItems!.map((DropdownItem item) {
          return PopupMenuItem<DropdownItem>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(item.label),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (DropdownItem newValue) {
        widget.onDropdownSelected?.call(newValue);
        widget.onDropdownChanged?.call(newValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.buttonColour ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: widget.labelColour ?? Theme.of(context).colorScheme.surface),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: widget.labelColour ?? Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context, bool isDisabled) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDisabled 
          ? Theme.of(context).colorScheme.surfaceVariant
          : widget.buttonColour ?? Theme.of(context).colorScheme.primary,
      foregroundColor: isDisabled
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : widget.labelColour ?? Theme.of(context).colorScheme.surface,
      minimumSize: const Size(double.maxFinite, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading || _isProcessing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.labelColour ?? Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.label),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) widget.icon!,
        if (widget.icon != null) const SizedBox(width: 8),
        Text(widget.label),
      ],
    );
  }
}

class DropdownItem {
  final IconData icon;
  final String label;

  const DropdownItem({required this.icon, required this.label});
}
