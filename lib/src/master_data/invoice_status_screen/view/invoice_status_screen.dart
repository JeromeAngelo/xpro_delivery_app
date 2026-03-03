
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import '../../../../core/common/app/features/invoice_status/domain/entity/invoice_status_entity.dart';
import '../../../../core/common/app/features/invoice_status/presentation/bloc/invoice_status_bloc.dart';
import '../../../../core/common/app/features/invoice_status/presentation/bloc/invoice_status_event.dart';
import '../../../../core/common/app/features/invoice_status/presentation/bloc/invoice_status_state.dart';
import '../../../../core/common/widgets/app_structure/desktop_layout.dart';
import '../../../../core/common/widgets/reusable_widgets/app_navigation_items.dart';
import '../widgets/export_dialog.dart';
import '../widgets/invoice_status_error_widget.dart';
import '../widgets/invoice_status_table.dart';
class InvoiceStatusScreen extends StatefulWidget {
  const InvoiceStatusScreen({super.key});

  @override
  State<InvoiceStatusScreen> createState() => _InvoiceStatusScreenState();
}

class _InvoiceStatusScreenState extends State<InvoiceStatusScreen> {
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 25;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _invoiceStatusFilter; // ✅ NEW (null = no filter)

  // keep last loaded list so export doesn’t break the UI state
  List<InvoiceStatusEntity> _cachedInvoices = const [];

  @override
  void initState() {
    super.initState();
    context.read<InvoiceStatusBloc>().add(GetAllInvoiceStatusEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _saveBytesToFile({
    required List<int> bytes,
    required String suggestedName,
    required String extension,
  }) async {
    if (kIsWeb) return null;

    final fileName = '$suggestedName.$extension';

    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return null;

    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      name: fileName,
      mimeType: extension == 'csv'
          ? 'text/csv'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    await xFile.saveTo(location.path);
    return location.path;
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = AppNavigationItems.generalTripItems();

    return DesktopLayout(
      navigationItems: navigationItems,
      currentRoute: '/invoice-status',
      onNavigate: (route) => context.go(route),
      onThemeToggle: () {},
      onNotificationTap: () {},
      onProfileTap: () {},
      child: BlocConsumer<InvoiceStatusBloc, InvoiceStatusState>(
        listener: (context, state) async {
          if (state is InvoiceStatusError) {
            _showSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          final bool isBusy =
              state is InvoiceStatusLoading || state is InvoiceStatusExporting;

          // cache loaded list
          if (state is AllInvoiceStatusLoaded) {
            _cachedInvoices = state.invoiceStatusList;
          }

          // choose data source (cached if not loaded yet)
          var invoices = List<InvoiceStatusEntity>.from(_cachedInvoices);

          // ✅ Search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            invoices = invoices.where((invoice) {
              return (invoice.id?.toLowerCase().contains(query) ?? false) ||
                  (invoice.invoiceData?.refId?.toLowerCase().contains(query) ?? false) ||
                  (invoice.invoiceData?.name?.toLowerCase().contains(query) ?? false) ||
                  (invoice.customer?.name?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          // ✅ Status filter (ONLY if user set filter)
          if (_invoiceStatusFilter != null && _invoiceStatusFilter!.isNotEmpty) {
            final selected = _invoiceStatusFilter!.toLowerCase().trim();
            invoices = invoices.where((invoice) {
              final s = (invoice.tripStatus ?? 'none').toLowerCase().trim();
              return s == selected;
            }).toList();
          }

          // ✅ Recompute pages AFTER filtering
          _totalPages = (invoices.length / _itemsPerPage).ceil();
          if (_totalPages == 0) _totalPages = 1;

          if (_currentPage > _totalPages) {
            _currentPage = 1;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage) > invoices.length
              ? invoices.length
              : (startIndex + _itemsPerPage);

          final paginatedInvoices = startIndex < invoices.length
              ? invoices.sublist(startIndex, endIndex)
              : <InvoiceStatusEntity>[];

          if (state is InvoiceStatusInitial && _cachedInvoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceStatusError && _cachedInvoices.isEmpty) {
            return InvoiceStatusErrorWidget(errorMessage: state.message);
          }

          return SingleChildScrollView(
            child: InvoiceStatusTable(
              invoices: paginatedInvoices,
              isLoading: isBusy && _cachedInvoices.isEmpty,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },

              // ✅ NEW: receive filter from table (filter full list, then paginate)
              onStatusFilterChanged: (status) {
                setState(() {
                  _invoiceStatusFilter = status; // null clears filter
                  _currentPage = 1;
                });
              },

              customIcon: Icons.upload_file_rounded,
              customFunction: () {
                ExportInvoiceStatusDialog.show(
                  context,
                  onExportCsv: () async {
                    try {
                      _showSnackBar(context, 'Preparing CSV export...');

                      final bloc = context.read<InvoiceStatusBloc>();
                      final bytesResult = await bloc.exportCsvBytesDirect();

                      final savedPath = await _saveBytesToFile(
                        bytes: bytesResult,
                        suggestedName:
                            'invoice_status_${DateTime.now().millisecondsSinceEpoch}',
                        extension: 'csv',
                      );

                      if (savedPath == null) {
                        _showSnackBar(context, 'Export cancelled.');
                        return;
                      }

                      _showSnackBar(context, 'CSV exported: $savedPath');
                    } catch (e) {
                      _showSnackBar(
                        context,
                        'CSV export failed: $e',
                        isError: true,
                      );
                    }
                  },
                  onExportExcel: () async {
                    try {
                      _showSnackBar(context, 'Preparing Excel export...');

                      final bloc = context.read<InvoiceStatusBloc>();
                      final bytesResult = await bloc.exportExcelBytesDirect();

                      final savedPath = await _saveBytesToFile(
                        bytes: bytesResult,
                        suggestedName:
                            'invoice_status_${DateTime.now().millisecondsSinceEpoch}',
                        extension: 'xlsx',
                      );

                      if (savedPath == null) {
                        _showSnackBar(context, 'Export cancelled.');
                        return;
                      }

                      _showSnackBar(context, 'Excel exported: $savedPath');
                    } catch (e) {
                      _showSnackBar(
                        context,
                        'Excel export failed: $e',
                        isError: true,
                      );
                    }
                  },
                );
              },
              errorMessage: null,
              onRetry: () => context
                  .read<InvoiceStatusBloc>()
                  .add(GetAllInvoiceStatusEvent()),
            ),
          );
        },
      ),
    );
  }
}