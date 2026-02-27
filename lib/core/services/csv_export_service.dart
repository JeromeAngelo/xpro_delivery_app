import 'dart:convert';

import '../common/app/features/invoice_status/domain/entity/invoice_status_entity.dart';

String _csvEscape(String v) {
  final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r');
  var out = v.replaceAll('"', '""');
  if (needsQuotes) out = '"$out"';
  return out;
}

List<int> buildInvoiceStatusCsvBytes(List<InvoiceStatusEntity> items) {

  
  final rows = <List<String>>[
    ['id', 'name', 'created', 'updated'],
    ...items.map((e) => [
      e.id ?? '',
      e.invoiceData?.name ?? e.invoiceData?.name  ?? '', // adjust based on your entity fields
      e.customer?.name ?? e.invoiceData?.name  ?? '', // adjust based on your entity fields
      e.tripStatus ?? '',
      
      (e.created?.toIso8601String() ?? ''),
      (e.updated?.toIso8601String() ?? ''),
    ]),
  ];

  final csv = rows
      .map((r) => r.map(_csvEscape).join(','))
      .join('\r\n');

  return utf8.encode(csv);
}