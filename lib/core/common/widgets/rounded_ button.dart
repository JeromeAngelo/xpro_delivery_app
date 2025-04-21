import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    required this.label,
    required this.onPressed,
    this.buttonColour,
    this.labelColour,
    this.icon,
    this.dropdownItems,
    this.onDropdownSelected,
    this.onDropdownChanged,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? buttonColour;
  final Color? labelColour;
  final Icon? icon;

  final List<DropdownItem>? dropdownItems;
  final Function(DropdownItem)? onDropdownSelected;
  final Function(DropdownItem?)? onDropdownChanged;

  @override
  Widget build(BuildContext context) {
    return dropdownItems != null
        ? _buildDropdownButton(context)
        : _buildRegularButton(context);
  }

  Widget _buildRegularButton(BuildContext context) {
    return ElevatedButton(
      style: _buttonStyle(context),
      onPressed: onPressed,
      child: _buildButtonContent(),
    );
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
        return dropdownItems!.map((DropdownItem item) {
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
        onDropdownSelected?.call(newValue);
        onDropdownChanged?.call(newValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: buttonColour ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: labelColour ?? Theme.of(context).colorScheme.surface),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: labelColour ?? Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: buttonColour ?? Theme.of(context).colorScheme.primary,
      foregroundColor: labelColour ?? Theme.of(context).colorScheme.surface,
      minimumSize: const Size(double.maxFinite, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) icon!,
        if (icon != null) const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class DropdownItem {
  final IconData icon;
  final String label;

  const DropdownItem({required this.icon, required this.label});
}
