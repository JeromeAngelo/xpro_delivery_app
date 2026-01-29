import 'package:flutter/material.dart';

class FormSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;
  final IconData? icon;

  const FormSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: isFullWidth ? const Size(double.infinity, 48) : null,
    );

    if (isLoading) {
      return SizedBox(
        height: 48,
        width: isFullWidth ? double.infinity : 120,
        child: ElevatedButton(
          onPressed: null,
          style: buttonStyle,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return SizedBox(
        height: 48,
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: buttonStyle,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(label),
      ),
    );
  }
}

class FormCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const FormCancelButton({
    super.key,
    this.label = 'Cancel',
    required this.onPressed,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class FormButtonsRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final bool isLoading;
  final IconData? submitIcon;

  const FormButtonsRow({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.cancelLabel = 'Cancel',
    this.submitLabel = 'Submit',
    this.isLoading = false,
    this.submitIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FormCancelButton(
          label: cancelLabel,
          onPressed: onCancel,
        ),
        const SizedBox(width: 16),
        FormSubmitButton(
          label: submitLabel,
          onPressed: onSubmit,
          isLoading: isLoading,
          icon: submitIcon,
        ),
      ],
    );
  }
}
