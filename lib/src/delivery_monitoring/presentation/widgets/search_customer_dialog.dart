import 'package:flutter/material.dart';

class CustomerSearchDialog extends StatelessWidget {
  final TextEditingController controller;

  /// Optional search callback
  final VoidCallback? onSearch;

  const CustomerSearchDialog({
    super.key,
    required this.controller,
    this.onSearch,
  });

  /// Helper method to open the dialog
  static Future<void> show(
    BuildContext context, {
    required TextEditingController controller,
    VoidCallback? onSearch,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CustomerSearchDialog(
        controller: controller,
        onSearch: onSearch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: const Row(
        children: [
          Icon(Icons.search, color: Colors.blue),
          SizedBox(width: 8),
          Text('Search Customer'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _handleSearch(context),
              decoration: const InputDecoration(
                hintText: 'Enter customer name or trip number ID...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'You can search customer by:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Row(
              children: [
                Icon(Icons.circle, size: 6, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer name',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Row(
              children: [
                Icon(Icons.circle, size: 6, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trip number ID',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Search'),
          onPressed: () => _handleSearch(context),
        ),
      ],
    );
  }

  void _handleSearch(BuildContext context) {
    Navigator.of(context).pop();

    if (onSearch != null) {
      onSearch!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer search functionality coming soon!'),
        ),
      );
    }
  }
}