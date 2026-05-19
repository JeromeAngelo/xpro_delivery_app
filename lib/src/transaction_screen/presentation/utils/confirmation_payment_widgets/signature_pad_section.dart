import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class SignaturePadSection extends StatelessWidget {
  final GlobalKey<SfSignaturePadState> signaturePadKey;
  final VoidCallback onReset;

  const SignaturePadSection({
    super.key,
    required this.signaturePadKey,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: SfSignaturePad(
            key: signaturePadKey,
            backgroundColor: const Color.fromARGB(40, 199, 199, 199),
            onDrawEnd: () {},
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Row(
            children: [
              Text(
                'Customer Signature',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 3,
          right: 8,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onReset,
              ),
              Text(
                'Reset',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
