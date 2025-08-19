import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/data/model/log_entry_model.dart';

import '../../../../../../../../enums/log_level.dart';

abstract class LogsLocalDatasource {
  /// Add a new log entry
  Future<void> addLog(LogEntryModel logEntry);

  /// Get all logs
  Future<List<LogEntryModel>> getAllLogs();

  /// Clear all logs
  Future<void> clearAllLogs();

  /// Generate PDF of all logs and return file path
  Future<String> generateLogsPdf();

  /// Get logs that haven't been synced to remote
  Future<List<LogEntryModel>> getUnsyncedLogs();

  /// Mark logs as synced after successful remote upload
  Future<void> markLogsAsSynced(List<String> logIds);
}

class LogsLocalDatasourceImpl implements LogsLocalDatasource {
  LogsLocalDatasourceImpl() {
    _initializeStorage();
  }

  final List<LogEntryModel> _logs = [];
  final Set<String> _syncedLogIds = {}; // Track which logs have been synced

  void _initializeStorage() {
    debugPrint('📝 Initializing logs local storage');
  }

  @override
  Future<void> addLog(LogEntryModel logEntry) async {
    try {
      _logs.add(logEntry);
      debugPrint('✅ Log added: [${logEntry.level?.name.toUpperCase() ?? 'DEBUG'}] ${logEntry.message ?? 'No message'}');
    } catch (e) {
      debugPrint('❌ Failed to add log: $e');
    }
  }

  @override
  Future<List<LogEntryModel>> getAllLogs() async {
    try {
      // Sort logs by timestamp (newest first)
      final sortedLogs = List<LogEntryModel>.from(_logs)
        ..sort((a, b) {
          final aTime = a.timestamp ?? DateTime(1970);
          final bTime = b.timestamp ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
      
      debugPrint('📋 Retrieved ${sortedLogs.length} logs');
      return sortedLogs;
    } catch (e) {
      debugPrint('❌ Failed to get logs: $e');
      return [];
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      final count = _logs.length;
      _logs.clear();
      debugPrint('🗑️ Cleared $count logs');
    } catch (e) {
      debugPrint('❌ Failed to clear logs: $e');
    }
  }

  @override
  Future<String> generateLogsPdf() async {
    try {
      debugPrint('📄 Generating logs PDF...');

      final pdf = pw.Document();
      final logs = await getAllLogs();

      // Create pages with logs
      const logsPerPage = 20;
      final totalPages = (logs.length / logsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * logsPerPage;
        final endIndex = (startIndex + logsPerPage < logs.length) 
            ? startIndex + logsPerPage 
            : logs.length;
        
        final pageLogs = logs.sublist(startIndex, endIndex);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      border: pw.Border.all(),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Application Logs Report',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Page ${pageIndex + 1} of $totalPages',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  
                  // Summary info (only on first page)
                  if (pageIndex == 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Report Summary',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text('Generated: ${DateTime.now().toString()}'),
                          pw.Text('Total Logs: ${logs.length}'),
                          pw.Text('Date Range: ${logs.isNotEmpty ? (logs.last.timestamp?.toString().split(' ')[0] ?? 'N/A') : 'N/A'} to ${logs.isNotEmpty ? (logs.first.timestamp?.toString().split(' ')[0] ?? 'N/A') : 'N/A'}'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),
                  ],

                  // Logs table
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(60),  // Time
                        1: const pw.FixedColumnWidth(50),  // Level
                        2: const pw.FixedColumnWidth(80),  // Category
                        3: const pw.FlexColumnWidth(3),    // Message
                      },
                      children: [
                        // Table header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Time',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Level',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Category',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Message',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Log entries
                        ...pageLogs.map((log) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                log.timestamp != null 
                                    ? '${log.timestamp!.hour.toString().padLeft(2, '0')}:${log.timestamp!.minute.toString().padLeft(2, '0')}'
                                    : '--:--',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                log.level?.name.toUpperCase() ?? 'DEBUG',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: _getLogLevelColor(log.level ?? LogLevel.debug),
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                log.category?.name ?? 'general',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                log.message ?? 'No message',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/logs_report_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF generated successfully: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Failed to generate PDF: $e');
      throw Exception('Failed to generate logs PDF: $e');
    }
  }

  PdfColor _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return PdfColors.red;
      case LogLevel.warning:
        return PdfColors.orange;
      case LogLevel.success:
        return PdfColors.green;
      case LogLevel.info:
        return PdfColors.blue;
      case LogLevel.debug:
        return PdfColors.grey;
    }
  }

  @override
  Future<List<LogEntryModel>> getUnsyncedLogs() async {
    try {
      // Get logs that haven't been synced yet
      final unsyncedLogs = _logs.where((log) {
        return log.id != null && !_syncedLogIds.contains(log.id!);
      }).toList();
      
      debugPrint('📊 Found ${unsyncedLogs.length} unsynced logs out of ${_logs.length} total');
      return unsyncedLogs;
    } catch (e) {
      debugPrint('❌ Failed to get unsynced logs: $e');
      return [];
    }
  }

  @override
  Future<void> markLogsAsSynced(List<String> logIds) async {
    try {
      // Add log IDs to synced set
      _syncedLogIds.addAll(logIds);
      debugPrint('✅ Marked ${logIds.length} logs as synced');
      debugPrint('📊 Total synced logs: ${_syncedLogIds.length}');
    } catch (e) {
      debugPrint('❌ Failed to mark logs as synced: $e');
    }
  }
}
