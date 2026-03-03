import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/filter_widgets/filter_option.dart';

class DataTableLayout extends StatefulWidget {
  final String title;
  final Widget? searchBar;
  final VoidCallback? onCreatePressed;
  final String createButtonText;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isLoading;
  final bool enableSelection;
  final String? errorMessage; // New parameter for error message
  final VoidCallback? onRetry; // New parameter for retry callback
  final VoidCallback? onFiltered;
  final VoidCallback? onDeleted;
  final Function(List<int>)? onRowsSelected; // Callback for selected rows
  final String dataLength;
  final List<FilterCategory>? filterCategories;
  final Function(Map<String, List<dynamic>>)? onFilterApplied;
  // New parameters for custom actions
  final Widget?
  customActionWidget; // Custom widget to show when rows are selected
  final bool showCustomAction; // Whether to show the custom action
  final VoidCallback? onCustomAction; // Callback for custom action
  final String? customActionTooltip; // Tooltip for custom action
  final IconData? customActionIcon; // Icon for custom action
  final Color? customActionColor; // Color for custom action

  const DataTableLayout({
    super.key,
    required this.title,
    this.searchBar,
    this.onCreatePressed,
    this.createButtonText = 'Create New',
    required this.columns,
    required this.rows,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.isLoading = false,
    this.enableSelection = true,
    this.errorMessage,
    this.onRetry,
    this.onRowsSelected,
    required this.dataLength,
     this.onFiltered,
    required this.onDeleted,
    this.filterCategories,
    this.onFilterApplied,
    // New parameters
    this.customActionWidget,
    this.showCustomAction = false,
    this.onCustomAction,
    this.customActionTooltip,
    this.customActionIcon,
    this.customActionColor,
  });

  @override
  State<DataTableLayout> createState() => _DataTableLayoutState();
}

class _DataTableLayoutState extends State<DataTableLayout> {
  // Create explicit ScrollController for horizontal scrolling
  final ScrollController _horizontalScrollController = ScrollController();
  final GlobalKey _checkboxColumnKey = GlobalKey();
  final GlobalKey _showDeletekey = GlobalKey();
  final GlobalKey _showFilterKey = GlobalKey();

  final headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black, // or any color you prefer
  );

  // Track selected rows
  final List<int> _selectedRows = [];
  bool _selectAll = false;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _showFilterMenu(BuildContext context) {
    final RenderBox? renderBox =
        _showFilterKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
      ),
      Offset.zero &
          (Overlay.of(context).context.findRenderObject() as RenderBox).size,
    );

    // If no filter categories are provided, show a default menu
    if (widget.filterCategories == null || widget.filterCategories!.isEmpty) {
      showMenu<String>(
        context: context,
        position: position,
        items: [
          PopupMenuItem<String>(
            value: 'no_filters',
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('No filters available'),
              ],
            ),
          ),
        ],
      );
      return;
    }

    // Show menu with provided filter categories
    showMenu<String>(
      context: context,
      position: position,
      items: [
        ...widget.filterCategories!
            .map(
              (category) => PopupMenuItem<String>(
                value: category.id,
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Filter by ${category.title}'),
                  ],
                ),
              ),
            )
            .toList(),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear_all, color: Colors.red),
              const SizedBox(width: 8),
              Text('Clear All Filters', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;

      if (value == 'clear') {
        // Clear all filters
        if (widget.onFiltered != null) {
          widget.onFiltered!();
        }
        return;
      }

      // Find the selected category
      final selectedCategory = widget.filterCategories!.firstWhere(
        (category) => category.id == value,
        orElse: () => widget.filterCategories!.first,
      );

      // Show filter dialog for the selected category
      _showFilterDialog(context, selectedCategory);
    });
  }

  void _showFilterDialog(BuildContext context, FilterCategory category) {
  // Local copy so we can cancel without mutating original until Apply
  final options = category.options
      .map(
        (o) => FilterOption(
          id: o.id,
          label: o.label,
          value: o.value,
          isSelected: o.isSelected,
        ),
      )
      .toList();

  // For single select, track selected index (better UX)
  int? selectedIndex;
  if (!category.allowMultiple) {
    final idx = options.indexWhere((o) => o.isSelected);
    selectedIndex = idx >= 0 ? idx : null;
  }

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Widget buildOptionTile(int index) {
            final opt = options[index];

            // Card wrapper for pro look
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (category.allowMultiple) {
                        opt.isSelected = !opt.isSelected;
                      } else {
                        selectedIndex = index;
                        for (int i = 0; i < options.length; i++) {
                          options[i].isSelected = i == index;
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: opt.isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: opt.isSelected ? 1.2 : 1,
                      ),
                    ),
                    child: category.allowMultiple
                        ? CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            
                            dense: true,
                            title: Text(opt.label),
                            value: opt.isSelected,
                            controlAffinity: ListTileControlAffinity.trailing,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onChanged: (v) {
                              setState(() => opt.isSelected = v ?? false);
                            },
                          )
                        : RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            
                            dense: true,
                            title: Text(opt.label),
                            value: index,
                            groupValue: selectedIndex,
                            controlAffinity: ListTileControlAffinity.trailing,
                            onChanged: (v) {
                              setState(() {
                                selectedIndex = v;
                                for (int i = 0; i < options.length; i++) {
                                  options[i].isSelected = i == v;
                                }
                              });
                            },
                          ),
                  ),
                ),
              ),
            );
          }

          void clearAll() {
            setState(() {
              for (final o in options) {
                o.isSelected = false;
              }
              selectedIndex = null;
            });
          }

          void selectAll() {
            setState(() {
              for (final o in options) {
                o.isSelected = true;
              }
            });
          }

          final selectedCount = options.where((o) => o.isSelected).length;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(category.icon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filter by ${category.title}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.allowMultiple
                                    ? 'Select one or more options'
                                    : 'Select one option',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Selected counter chip
                        if (selectedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$selectedCount selected',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 14),

                    // Action row (Select all / Clear)
                    Row(
                      children: [
                        if (category.allowMultiple)
                          TextButton.icon(
                            onPressed: selectAll,
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Select all'),
                          ),
                        if (category.allowMultiple) const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: clearAll,
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear'),
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Options list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) => buildOptionTile(index),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),

                    // Footer actions
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            // Update original options
                            for (int i = 0; i < category.options.length; i++) {
                              category.options[i].isSelected = options[i].isSelected;
                            }

                            // Collect all selected filters across all categories
                            final Map<String, List<dynamic>> selectedFilters = {};
                            for (final cat in widget.filterCategories!) {
                              final selectedValues = cat.options
                                  .where((o) => o.isSelected)
                                  .map((o) => o.value)
                                  .toList();
                              if (selectedValues.isNotEmpty) {
                                selectedFilters[cat.id] = selectedValues;
                              }
                            }

                            widget.onFilterApplied?.call(selectedFilters);
                            widget.onFiltered?.call();

                            Navigator.pop(dialogContext);
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  void _showSelectionMenu(BuildContext context) {
    final RenderBox? renderBox =
        _checkboxColumnKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
      ),
      Offset.zero &
          (Overlay.of(context).context.findRenderObject() as RenderBox).size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'page',
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (bool? value) {
                  setState(() {
                    _selectAll = value ?? false;
                    _selectedRows.clear();

                    if (_selectAll) {
                      // Add all row indices to selected rows
                      for (int i = 0; i < widget.rows.length; i++) {
                        _selectedRows.add(i);
                      }
                    }

                    // Notify parent about selection change
                    if (widget.onRowsSelected != null) {
                      widget.onRowsSelected!(_selectedRows);
                    }
                  });
                  Navigator.pop(context);
                },
              ),
              Text('Select this page (${widget.rows.length})'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Checkbox(
                value: false, // This would need to be a separate state variable
                onChanged: (bool? value) {
                  // Logic to select all data across all pages
                  if (value == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected all ${widget.dataLength} items',
                        ),
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
              ),
              Text('Select all ${widget.dataLength}'),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteMenu(BuildContext context) {
    final RenderBox? renderBox =
        _showDeletekey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
      ),
      Offset.zero &
          (Overlay.of(context).context.findRenderObject() as RenderBox).size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Delete (${_selectedRows.length})'),
            ],
          ),
        ),
      ],
    ).then((String? value) {
      if (value == 'delete') {
        _showDeleteConfirmationDialog(context);
      }
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete ${_selectedRows.length} selected item${_selectedRows.length > 1 ? 's' : ''}?',
                ),
                const SizedBox(height: 10),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Call the onDeleted callback
                if (widget.onDeleted != null) {
                  widget.onDeleted!();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedRows = _selectedRows.isNotEmpty;
    bool hasActiveFilters() {
      if (widget.filterCategories == null) return false;

      for (var category in widget.filterCategories!) {
        for (var option in category.options) {
          if (option.isSelected) return true;
        }
      }
      return false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
          // Title row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search bar and Create button in the same row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Search bar (expanded to take available space)
                if (widget.searchBar != null)
                  Expanded(child: widget.searchBar!),

                // Add some spacing between search and button
                if (widget.searchBar != null && widget.onCreatePressed != null)
                  const Spacer(),

                // Create button
                if (widget.onCreatePressed != null)
                  ElevatedButton.icon(
                    onPressed: widget.onCreatePressed,
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    label: Text(
                      widget.createButtonText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Error message if present
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    if (widget.onRetry != null)
                      TextButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),

          // Data table content - Always show the table structure
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal scroll hint with conditional visibility for delete button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Replace the existing filter icon code with this
                      GestureDetector(
                        onTap: () => _showFilterMenu(context),
                        key: _showFilterKey,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.filter_alt_rounded,
                                color:
                                    hasActiveFilters()
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                              const SizedBox(width: 4),
                              if (hasActiveFilters())
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _getActiveFilterCount().toString(),
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      // Custom Action Widget (NEW)
                      Visibility(
                        visible:
                            hasSelectedRows &&
                            (widget.showCustomAction ||
                                widget.customActionWidget != null),
                        child:
                            widget.customActionWidget ??
                            GestureDetector(
                              onTap: widget.onCustomAction,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Tooltip(
                                  message:
                                      widget.customActionTooltip ??
                                      'Custom Action',
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        widget.customActionIcon ??
                                            Icons.more_vert,
                                        color:
                                            hasSelectedRows
                                                ? (widget.customActionColor ??
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary)
                                                : null,
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),

                      // Only show delete button when rows are selected
                      Visibility(
                        visible: hasSelectedRows,
                        child: GestureDetector(
                          onLongPress: () => _showDeleteMenu(context),
                          key: _showDeletekey,
                          onTap:
                              () => _showDeleteMenu(
                                context,
                              ), // Also allow regular tap for better UX
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.delete,
                                  color:
                                      hasSelectedRows
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : null,
                                ),
                                Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Table with horizontal scrolling - Always show the structure
                  Scrollbar(
                    controller: _horizontalScrollController,
                    thickness: 5,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalScrollController,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // Set a minimum width that's wider than the screen
                          minWidth: MediaQuery.of(context).size.width - 100,
                        ),
                        child: _buildTableContent(),
                      ),
                    ),
                  ),

                  // Pagination controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      // color: const Color.fromARGB(255, 36, 34, 34),
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed:
                              widget.currentPage > 1
                                  ? () => widget.onPageChanged(
                                    widget.currentPage - 1,
                                  )
                                  : null,
                          child: const Text('Previous'),
                        ),
                        Text(
                          'Page ${widget.currentPage}-${widget.totalPages} of ${widget.dataLength}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed:
                              widget.currentPage < widget.totalPages
                                  ? () => widget.onPageChanged(
                                    widget.currentPage + 1,
                                  )
                                  : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }

  int _getActiveFilterCount() {
    if (widget.filterCategories == null) return 0;

    int count = 0;
    for (var category in widget.filterCategories!) {
      for (var option in category.options) {
        if (option.isSelected) count++;
      }
    }
    return count;
  }

  // Build the appropriate table content based on state
  Widget _buildTableContent() {
    if (widget.isLoading) {
      return _buildShimmerTable();
    } else if (widget.rows.isEmpty) {
      // This handles both empty initial data and empty search results
      return _buildTableWithMessage(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.searchBar != null
                  ? 'No matching data found for your search'
                  : 'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.searchBar != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Try adjusting your search criteria',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
          ],
        ),
      );
    } else {
      try {
        // Create a new list of columns with a checkbox column at the beginning
        final List<DataColumn> columnsWithCheckbox = [
          DataColumn(
            label:
                widget.enableSelection
                    ? GestureDetector(
                      onTap: () => _showSelectionMenu(context),
                      key: _checkboxColumnKey,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (bool? value) {
                              setState(() {
                                _selectAll = value ?? false;
                                _selectedRows.clear();

                                if (_selectAll) {
                                  // Add all row indices to selected rows
                                  for (int i = 0; i < widget.rows.length; i++) {
                                    _selectedRows.add(i);
                                  }
                                }

                                // Notify parent about selection change
                                if (widget.onRowsSelected != null) {
                                  widget.onRowsSelected!(_selectedRows);
                                }
                              });
                            },
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
          ...widget.columns,
        ];

        // Create a new list of rows with a checkbox cell at the beginning of each row
        final List<DataRow> rowsWithCheckbox = List.generate(
          widget.rows.length,
          (index) {
            final isSelected = _selectedRows.contains(index);

            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(
                  widget.enableSelection
                      ? Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedRows.add(index);
                            } else {
                              _selectedRows.remove(index);
                            }

                            // Update selectAll checkbox
                            _selectAll =
                                _selectedRows.length == widget.rows.length;

                            // Notify parent about selection change
                            if (widget.onRowsSelected != null) {
                              widget.onRowsSelected!(_selectedRows);
                            }
                          });
                        },
                      )
                      : const SizedBox.shrink(),
                ),
                ...widget.rows[index].cells,
              ],
            );
          },
        );

        return DataTable(
          columns: columnsWithCheckbox,
          rows: rowsWithCheckbox,
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          headingTextStyle: headerStyle,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
          horizontalMargin: 16,
          columnSpacing: 24,
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        );
      } catch (e) {
        // If there's an error processing the data (like type mismatch),
        // show an error message instead of crashing
        debugPrint('Error rendering table data: $e');
        return _buildTableWithMessage(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error displaying data',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There was a problem with the data format',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (widget.onRetry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
            ],
          ),
        );
      }
    }
  }

  // Helper method to build a table with a centered message
  Widget _buildTableWithMessage(Widget messageWidget) {
    // Create a DataTable with the same columns but with a single row containing our message
    final List<DataColumn> columnsWithCheckbox = [
      DataColumn(
        label:
            widget.enableSelection
                ? Checkbox(value: false, onChanged: null)
                : const SizedBox.shrink(),
      ),
      ...widget.columns,
    ];

    return DataTable(
      columns: columnsWithCheckbox,
      rows: [
        DataRow(
          cells: [
            // First cell contains our message and spans all columns visually
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: messageWidget,
                ),
              ),
            ),
            // Add empty cells for the remaining columns
            for (int i = 1; i < columnsWithCheckbox.length; i++)
              const DataCell(SizedBox.shrink()),
          ],
        ),
      ],
      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
      headingTextStyle: TextStyle(color: Colors.black),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 64,
      horizontalMargin: 16,
      dataTextStyle: TextStyle(color: Colors.black),
      columnSpacing: 24,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: const Color.fromARGB(255, 100, 95, 95),
          width: 1,
        ),
      ),
    );
  }

  // Helper method to build a shimmer loading table
  Widget _buildShimmerTable() {
    return DataTable(
      columns: [
        DataColumn(
          label:
              widget.enableSelection
                  ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
        ...widget.columns.map(
          (column) => DataColumn(
            label: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
      rows: List.generate(
        15, // 15 rows of shimmer loading
        (index) => DataRow(
          cells: [
            DataCell(
              widget.enableSelection
                  ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  : const SizedBox.shrink(),
            ),
            ...List.generate(
              widget.columns.length,
              (cellIndex) => DataCell(
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width:
                        120 +
                        (cellIndex *
                            20 %
                            80), // Varying widths for natural look
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 64,
      horizontalMargin: 16,
      columnSpacing: 24,
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}
