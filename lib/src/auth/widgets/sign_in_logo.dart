import 'package:flutter/material.dart';

class SignInLogo extends StatelessWidget {
  final double size;

  const SignInLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.local_shipping, size: size * 0.5, color: Colors.white),
    );
  }
}
