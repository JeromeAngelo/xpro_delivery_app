import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class LogEntryTile extends StatelessWidget {
  final LogEntryEntity log;

  const LogEntryTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      title: log.message,
      subtitle: log.details ?? 'Category: ${log.category.name}',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getLogLevelColor(log.level).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getLogLevelColor(log.level)),
        ),
        child: Icon(
          _getLogLevelIcon(log.level),
          color: _getLogLevelColor(log.level),
          size: 20,
        ),
      ),
      trailing: Text(
        _formatTimestamp(log.timestamp),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: () => _showLogDetails(context, log),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Format: "July 29, 2025, 2pm"
    final formatter = DateFormat('MMMM d, y, ha');
    return formatter.format(timestamp);
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.debug:
        return Colors.grey;
    }
  }

  IconData _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.success:
        return Icons.check_circle;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.debug:
        return Icons.bug_report;
    }
  }

  void _showLogDetails(BuildContext context, LogEntryEntity log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getLogLevelIcon(log.level),
              color: _getLogLevelColor(log.level),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Log Details',
                style: TextStyle(
                  color: _getLogLevelColor(log.level),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Level', log.level.name.toUpperCase()),
              _buildDetailRow('Category', log.category.name),
              _buildDetailRow('Time', _formatTimestamp(log.timestamp)),
              const Divider(),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(log.message),
              if (log.details != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(log.details!),
              ],
              if (log.userId != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('User ID', log.userId!),
              ],
              if (log.tripId != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Trip ID', log.tripId!),
              ],
              if (log.deliveryId != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Delivery ID', log.deliveryId!),
              ],
              if (log.stackTrace != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    log.stackTrace!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
