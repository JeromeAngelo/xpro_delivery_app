import 'package:flutter/material.dart';

class InvoicePresetGroupSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const InvoicePresetGroupSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search invoice preset groups...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}
