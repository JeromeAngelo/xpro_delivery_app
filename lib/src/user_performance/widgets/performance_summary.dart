import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/entity/user_performance_entity.dart';

class PerformanceSummary extends StatelessWidget {
  final UserPerformanceEntity userPerformance;

  const PerformanceSummary({
    super.key,
    required this.userPerformance,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icons.summarize,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
              context,
              'Overall Rating',
              userPerformance.performanceStatus,
              _getStatusIcon(userPerformance.performanceStatus),
              _getStatusColor(userPerformance.performanceStatus),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              'Performance Level',
              userPerformance.hasGoodPerformance ? 'Good Performance' : 'Needs Improvement',
              userPerformance.hasGoodPerformance ? Icons.thumb_up : Icons.thumb_down,
              userPerformance.hasGoodPerformance ? Colors.green : Colors.red,
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              'Last Updated',
              _formatDate(userPerformance.updated),
              Icons.access_time,
              Colors.grey,
            ),
            if (userPerformance.created != null) ...[
              const Divider(height: 24),
              _buildSummaryRow(
                context,
                'Member Since',
                _formatDate(userPerformance.created),
                Icons.calendar_today,
                Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'average':
        return Icons.horizontal_rule;
      case 'below average':
        return Icons.thumb_down;
      case 'poor':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'below average':
        return Colors.deepOrange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
