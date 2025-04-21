import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/status_drawers.dart';

class UpdateDeliveryBtn extends StatelessWidget {
  final String currentStatus;
  final bool isDisabled;
  final String customerId;

  const UpdateDeliveryBtn({
    super.key,
    required this.currentStatus,
    required this.customerId,
    this.isDisabled = false,
  });

  bool get _shouldShowButton {
    final status = currentStatus.toLowerCase();
    return status.isNotEmpty &&
        status != 'end delivery' &&
        status != 'mark as undeliverable';
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowButton) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: RoundedButton(
        label: 'Update Delivery',
        onPressed: isDisabled ? () {} : () => _showStatusDrawer(context),
        buttonColour: isDisabled
            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
            : Theme.of(context).colorScheme.primary,
        labelColour: isDisabled
            ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
            : Theme.of(context).colorScheme.onPrimary,
        icon: Icon(
          Icons.update_rounded,
          color: isDisabled
              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
              : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  void _showStatusDrawer(BuildContext context) {
    if (!isDisabled) {
      showModalBottomSheet(
        isDismissible: true,
        showDragHandle: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context) {
          return UpdateStatusDrawer(customerId: customerId);
        },
      );
    }
  }
}
