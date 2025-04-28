import 'package:flutter/material.dart';

class EmptyScreenMessage extends StatelessWidget {
  const EmptyScreenMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Image.asset(
              'assets/images/no-results.png',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
