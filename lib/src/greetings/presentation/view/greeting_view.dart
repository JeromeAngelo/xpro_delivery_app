import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GreetingView extends StatelessWidget {
  const GreetingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for success animation/image
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),

              // Congratulations text
              Text(
                'Great job!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),

              // Motivational message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You have successfully completed all deliveries for today. Time to wrap up!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 48),

              // Action button
              FilledButton.icon(
                onPressed: () => context.push('/final-screen'),
                icon: const Icon(Icons.summarize),
                label: const Text('View Trip Summary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
