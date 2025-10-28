import 'package:flutter/material.dart';

class DynamicDataTable<T> extends StatefulWidget {
  /// List of data items to display in the table
  final List<T> data;

  /// Function to build column definitions
  final List<DataColumn> Function(BuildContext) columnBuilder;

  /// Function to build a row for each data item
  final DataRow Function(T item, int index) rowBuilder;

  /// Optional search controller
  final TextEditingController? searchController;

  /// Function to filter data based on search query
  final bool Function(T item, String query)? searchFilter;

  /// Optional function to handle row selection
  final void Function(T? selectedItem)? onSelect;

  /// Whether to show checkboxes for row selection
  final bool showCheckboxes;

  /// Whether the table is in loading state
  final bool isLoading;

  /// Message to display when no data is available
  final String emptyMessage;

  /// Number of items to show per page
  final int itemsPerPage;

  /// Optional custom header widget
  final Widget? headerWidget;

  /// Optional custom loading widget
  final Widget? loadingWidget;

  /// Optional custom empty state widget
  final Widget? emptyWidget;

  /// Table border configuration
  final TableBorder? tableBorder;

  /// Table column spacing
  final double columnSpacing;

  /// Table horizontal margin
  final double horizontalMargin;

  /// Whether to show the search field
  final bool showSearch;

  /// Search field decoration
  final InputDecoration? searchDecoration;

  /// Optional button placeholder
  final Widget? buttonPlaceholder;

  /// Maximum height for the table container
  final double? maxHeight;

  const DynamicDataTable({
    super.key,
    required this.data,
    required this.columnBuilder,
    required this.rowBuilder,
    this.searchController,
    this.searchFilter,
    this.onSelect,
    this.showCheckboxes = false,
    this.isLoading = false,
    this.emptyMessage = 'No data available',
    this.itemsPerPage = 100,
    this.headerWidget,
    this.loadingWidget,
    this.emptyWidget,
    this.tableBorder,
    this.columnSpacing = 56.0,
    this.horizontalMargin = 24.0,
    this.showSearch = true,
    this.searchDecoration,
    this.buttonPlaceholder,
    this.maxHeight,
  });

  @override
  State<DynamicDataTable<T>> createState() => _DynamicDataTableState<T>();
}

class _DynamicDataTableState<T> extends State<DynamicDataTable<T>> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  int _currentPage = 1;
  T? _selectedItem;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1; // Reset to first page when search changes
    });
  }

  List<T> get _filteredData {
    if (_searchQuery.isEmpty || widget.searchFilter == null) {
      return widget.data;
    }

    return widget.data
        .where((item) => widget.searchFilter!(item, _searchQuery))
        .toList();
  }

  List<T> get _paginatedData {
    final startIndex = (_currentPage - 1) * widget.itemsPerPage;
    final endIndex =
        startIndex + widget.itemsPerPage > _filteredData.length
            ? _filteredData.length
            : startIndex + widget.itemsPerPage;

    return startIndex < _filteredData.length
        ? _filteredData.sublist(startIndex, endIndex)
        : [];
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Custom header if provided
        if (widget.headerWidget != null) widget.headerWidget!,

        // Data table
        Expanded(
          child:
              widget.isLoading
                  ? widget.loadingWidget ??
                      const Center(child: CircularProgressIndicator())
                  : _filteredData.isEmpty
                  ? widget.emptyWidget ??
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_rows_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.emptyMessage,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                  : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Scrollable table container
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      widget.maxHeight ?? double.infinity,
                                ),
                                child: Scrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  child: Scrollbar(
                                    controller: _horizontalScrollController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    notificationPredicate:
                                        (notification) =>
                                            notification.depth == 1,
                                    child: SingleChildScrollView(
                                      controller: _verticalScrollController,
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        controller: _horizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: DataTable(
                                            columns: widget.columnBuilder(
                                              context,
                                            ),
                                            rows:
                                                _paginatedData
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                      final index = entry.key;
                                                      final item = entry.value;
                                                      return widget.rowBuilder(
                                                        item,
                                                        index,
                                                      );
                                                    })
                                                    .toList(),
                                            showCheckboxColumn:
                                                widget.showCheckboxes,
                                            border: widget.tableBorder,
                                            columnSpacing: widget.columnSpacing,
                                            horizontalMargin:
                                                widget.horizontalMargin,

                                            headingRowColor:
                                                MaterialStateProperty.all(
                                                  Colors.grey[100],
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Pagination and button placeholder
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${_paginatedData.length} of ${_filteredData.length} items',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              // Button placeholder
                              widget.buttonPlaceholder ?? Container(),
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
}
