import 'package:flutter/material.dart';

class FilterCategory {
  final String id;
  final String title;
  final IconData icon;
  final List<FilterOption> options;
  final bool allowMultiple;

  const FilterCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.options,
    this.allowMultiple = true,
  });
}

class FilterOption {
  final IconData? icon;
  final String id;
  final String label;
  final dynamic value;
  bool isSelected;

  FilterOption({
    this.icon ,    required this.id,
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}
