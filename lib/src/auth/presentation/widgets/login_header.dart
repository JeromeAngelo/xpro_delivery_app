import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset('assets/images/app_icon.png', height: 100, width: 100),
        const SizedBox(height: 20),
        Text(
          'X-Pro Delivery Admin App',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Delivery Management System',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
