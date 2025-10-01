import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/domain/entity/user_performance_entity.dart';

class DeliveryAccuracyChart extends StatelessWidget {
  final UserPerformanceEntity userPerformance;

  const DeliveryAccuracyChart({
    super.key,
    required this.userPerformance,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = userPerformance.deliveryAccuracyPercentage;
    final successRate = userPerformance.successRate;
    final cancellationRate = userPerformance.cancellationRate;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressIndicator(
              context,
              'Delivery Accuracy',
              accuracy,
              Colors.blue,
              '${accuracy.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              context,
              'Success Rate',
              successRate,
              Colors.green,
              '${successRate.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              context,
              'Cancellation Rate',
              cancellationRate,
              Colors.red,
              '${cancellationRate.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    double value,
    Color color,
    String displayValue,
  ) {
    final percentage = value / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }
}
