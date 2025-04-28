import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:x_pro_delivery_app/core/common/widgets/ifields.dart';

class EndTripOdoInput extends StatefulWidget {
  final Function(String) onOdometerChanged;

  const EndTripOdoInput({super.key, required this.onOdometerChanged});

  @override
  State<EndTripOdoInput> createState() => _EndTripOdoInputState();
}

class _EndTripOdoInputState extends State<EndTripOdoInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set up listener to call the callback when text changes
    _controller.addListener(() {
      widget.onOdometerChanged(_controller.text);
    });

    // Auto-focus the field by setting focus after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      // Small delay to ensure the widget is fully built
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).unfocus();
        FocusScope.of(context).requestFocus(FocusNode());
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the vehicle odometer reading',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        IField(
          controller: _controller,
          keyboardType: TextInputType.number,
          hintText: 'Enter final odometer reading (e.g., 123456)',
          filled: true,
          fillColour: Theme.of(context).colorScheme.surfaceContainerHighest,
          overrideValidator: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Odometer reading is required';
            }
            if (value.length < 6) {
              return 'Please enter a complete 6-digit reading';
            }
            return null;
          },
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter the final odometer reading (6 digits)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
