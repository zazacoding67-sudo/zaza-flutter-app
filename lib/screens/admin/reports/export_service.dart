// lib/screens/admin/reports/export_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:html' as html;
import 'pdf_export_service.dart';

class ExportService {
  final PdfExportService _pdfExportService = PdfExportService();

  // CSV Export method
  Future<void> exportToCSV({
    required BuildContext context,
    required String fileName,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      if (data.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No data to export')));
        }
        return;
      }

      // Get headers from first data item
      final headers = data.isNotEmpty ? data.first.keys.toList() : [];

      // Convert data to CSV
      final List<List<dynamic>> rows = [];
      rows.add(headers);

      for (var row in data) {
        final rowData = headers.map((header) {
          final value = row[header];
          if (value is DateTime) {
            return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
          }
          return value?.toString() ?? '';
        }).toList();
        rows.add(rowData);
      }

      final csv = const ListToCsvConverter().convert(rows);

      // Handle different platforms
      if (kIsWeb) {
        // For web platform
        _downloadFileWeb(csv, '$fileName.csv');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading $fileName.csv'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // For mobile/desktop
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName.csv');
        await file.writeAsString(csv);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File saved: ${file.path}')));
        }
      }
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  // Web-specific download helper
  void _downloadFileWeb(String content, String fileName) {
    try {
      final bytes = utf8.encode(content);
      final blob = base64.encode(bytes);

      // Create a download link and trigger click
      final anchor = html.AnchorElement(href: 'data:text/csv;base64,$blob')
        ..setAttribute('download', fileName)
        ..click();
    } catch (e) {
      debugPrint('Web download error: $e');
    }
  }

  // PDF Export method
  // In export_service.dart, make sure the exportToPDF method looks like this:
  Future<void> exportToPDF({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> data,
    required String reportType,
  }) async {
    try {
      await _pdfExportService.exportReportToPDF(
        context: context,
        title: title,
        reportData: data,
        reportType: reportType,
      );
    } catch (e) {
      debugPrint('Error in exportToPDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }

  // Combined export method
  Future<void> exportMultipleReports({
    required BuildContext context,
    required List<Map<String, dynamic>> reports,
    required String format,
  }) async {
    if (format == 'csv') {
      for (var i = 0; i < reports.length; i++) {
        final report = reports[i];
        await exportToCSV(
          context: context,
          fileName: 'report_${i + 1}',
          data: report['data'] ?? [],
        );
      }
    } else if (format == 'pdf') {
      // For now, export the first report only
      if (reports.isNotEmpty) {
        await exportToPDF(
          context: context,
          title: 'Combined Report',
          data: reports.first,
          reportType: 'combined',
        );
      }
    }
  }
}
