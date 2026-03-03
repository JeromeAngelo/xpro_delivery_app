import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/data_table_layout.dart';

import '../../../../../core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';

class InvoiceItemsDeliveryDataWidget extends StatefulWidget {
  final DeliveryDataEntity? deliveryData;
  final bool isLoading;

  /// Optional actions
  final VoidCallback? onViewItem;
  final VoidCallback? onEditItem;

  /// Optional: open a screen that shows all items (or item details)
  final VoidCallback? onViewItems;

  const InvoiceItemsDeliveryDataWidget({
    super.key,
    required this.deliveryData,
    this.isLoading = false,
    this.onViewItem,
    this.onEditItem,
    this.onViewItems,
  });

  @override
  State<InvoiceItemsDeliveryDataWidget> createState() =>
      _InvoiceItemsDeliveryDataWidgetState();
}

class _InvoiceItemsDeliveryDataWidgetState
    extends State<InvoiceItemsDeliveryDataWidget> {
  @override
  Widget build(BuildContext context) {
    final headerStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final items = _getInvoiceItems();

    return DataTableLayout(
      title: 'Invoice Items',
      onCreatePressed: widget.onViewItems,
      createButtonText: 'View Items',
      columns: [
        //DataColumn(label: Text('Item ID', style: headerStyle)),
        DataColumn(label: Text('Ref ID', style: headerStyle)),

        DataColumn(label: Text('Item Name', style: headerStyle)),
        DataColumn(label: Text('Brand', style: headerStyle)),
        DataColumn(label: Text('UOM', style: headerStyle)),
        DataColumn(label: Text('Qty', style: headerStyle)),
        // DataColumn(label: Text('Base Qty', style: headerStyle)),
        DataColumn(label: Text('UOM Price', style: headerStyle)),
        DataColumn(label: Text('Total', style: headerStyle)),
       // DataColumn(label: Text('Invoice', style: headerStyle)),
        // DataColumn(label: Text('Customer', style: headerStyle)),
        // DataColumn(label: Text('Delivery No.', style: headerStyle)),
        // DataColumn(label: Text('Created Date', style: headerStyle)),
        DataColumn(label: Text('Actions', style: headerStyle)),
      ],
      rows:
          widget.isLoading ? _buildLoadingRows(items.length) : _buildItemRows(),
      currentPage: 1,
      totalPages: 1,
      onPageChanged: (_) {},
      isLoading: widget.isLoading,
      dataLength: items.isEmpty ? '0' : '${items.length}',
      onDeleted: () {},
    );
  }

  /// NOTE:
  /// Adjust this according to how you store invoice items in DeliveryDataEntity.
  /// Common patterns:
  /// - deliveryData.invoiceItems
  /// - deliveryData.invoices[i].items
  /// - deliveryData.invoiceItemsByInvoice
  List<InvoiceItemsEntity> _getInvoiceItems() {
    // ✅ Try the most common field name first
    final dd = widget.deliveryData;

    // If your DeliveryDataEntity already has `invoiceItems`, use that:
    final direct = (dd as dynamic)?.invoiceItems;
    if (direct is List<InvoiceItemsEntity>) return direct;

    // If items are under invoices (e.g., invoices[].items), flatten them:
    final invoices = (dd as dynamic)?.invoices;
    if (invoices is List) {
      final List<InvoiceItemsEntity> flattened = [];
      for (final inv in invoices) {
        final invItems = (inv as dynamic)?.items;
        if (invItems is List<InvoiceItemsEntity>) {
          flattened.addAll(invItems);
        }
      }
      return flattened;
    }

    return const <InvoiceItemsEntity>[];
  }

  List<DataRow> _buildLoadingRows(int actualCount) {
    final count = actualCount > 0 ? actualCount : 5;

    return List.generate(count, (_) {
      return DataRow(
        cells: [
          DataCell(_buildShimmerCell(80)),
          DataCell(_buildShimmerCell(180)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(70)),
          DataCell(_buildShimmerCell(60)),
          DataCell(_buildShimmerCell(80)),
          DataCell(_buildShimmerCell(90)),
          DataCell(_buildShimmerCell(100)),
          DataCell(_buildShimmerCell(140)),
          DataCell(_buildShimmerCell(140)),
          DataCell(_buildShimmerCell(120)),
          DataCell(_buildShimmerCell(140)),
          DataCell(
            Row(
              children: [
                _buildShimmerIcon(),
                const SizedBox(width: 8),
                _buildShimmerIcon(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildShimmerCell(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  List<DataRow> _buildItemRows() {
    final items = _getInvoiceItems();

    if (items.isEmpty) {
      return [
        DataRow(
          cells: [
            const DataCell(Text('N/A')),
            const DataCell(Text('No Invoice Items')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('0')),
            const DataCell(Text('0')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            const DataCell(Text('N/A')),
            DataCell(Text(widget.deliveryData?.customer?.name ?? 'N/A')),
            DataCell(Text(widget.deliveryData?.deliveryNumber ?? 'N/A')),
            DataCell(Text(_formatDate(widget.deliveryData?.created))),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                tooltip: 'View Items',
                onPressed:
                    widget.onViewItems ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No items to view.')),
                      );
                    },
              ),
            ),
          ],
        ),
      ];
    }

    return items.map((item) {
      // final invoiceNameOrId =
      //     item.invoiceData?.name ?? item.invoiceData?.id ?? 'N/A';

      return DataRow(
        cells: [
          // DataCell(Text(item.id ?? 'N/A'), onTap: () => _onViewItem(item)),
          DataCell(Text(item.refId ?? 'N/A'), onTap: () => _onViewItem(item)),

          DataCell(Text(item.name ?? 'N/A'), onTap: () => _onViewItem(item)),
          DataCell(Text(item.brand ?? 'N/A'), onTap: () => _onViewItem(item)),
          DataCell(
            _buildChipCell(item.uom ?? 'N/A'),
            onTap: () => _onViewItem(item),
          ),
          DataCell(
            Text(_formatNumber(item.quantity)),
            onTap: () => _onViewItem(item),
          ),
          // DataCell(
          //   Text(_formatNumber(item.totalBaseQuantity)),
          //   onTap: () => _onViewItem(item),
          // ),
          DataCell(
            _buildMoneyCell(item.uomPrice),
            onTap: () => _onViewItem(item),
          ),
          DataCell(
            _buildTotalAmountCell(item.totalAmount),
            onTap: () => _onViewItem(item),
          ),
         // DataCell(Text(invoiceNameOrId), onTap: () => _onViewItem(item)),
          // ✅ Still connected to DeliveryData
          // DataCell(
          //   Text(widget.deliveryData?.customer?.name ?? 'N/A'),
          //   onTap: () => _onViewItem(item),
          // ),
          // DataCell(
          //   Text(widget.deliveryData?.deliveryNumber ?? 'N/A'),
          //   onTap: () => _onViewItem(item),
          // ),
          // DataCell(
          //   Text(_formatDate(item.created ?? widget.deliveryData?.created)),
          //   onTap: () => _onViewItem(item),
          // ),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'View Item',
                  onPressed: () => _onViewItem(item),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit Item',
                  onPressed: widget.onEditItem,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildChipCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMoneyCell(double? amount) {
    final text = amount == null ? 'N/A' : '₱${_formatNumber(amount)}';
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: amount == null ? Colors.grey[600] : Colors.black,
      ),
    );
  }

  Widget _buildTotalAmountCell(double? total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: total != null ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        total == null ? 'N/A' : '₱${_formatNumber(total)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: total != null ? Colors.green[700] : Colors.grey[600],
        ),
      ),
    );
  }

  void _onViewItem(InvoiceItemsEntity item) {
    if (widget.onViewItem != null) {
      widget.onViewItem!();
      return;
    }

    // Default fallback: show a small snack for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing item: ${item.name ?? item.id ?? "N/A"}')),
    );
  }

  String _formatNumber(num? value) {
    if (value == null) return '0';
    try {
      // You can adjust decimal formatting if needed
      final formatter = NumberFormat('#,##0.##');
      return formatter.format(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MM/dd/yyyy hh:mm a').format(date);
    } catch (e) {
      debugPrint('❌ Error formatting date: $e');
      return 'Invalid Date';
    }
  }
}
