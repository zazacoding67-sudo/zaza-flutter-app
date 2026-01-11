// lib/screens/admin/reports/pdf_export_service.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  Future<void> exportReportToPDF({
    required BuildContext context,
    required String title,
    required Map<String, dynamic> reportData,
    required String reportType,
  }) async {
    try {
      final pdf = await _generateReportPDF(
        title: title,
        reportData: reportData,
        reportType: reportType,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name:
            '${title}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generateReportPDF({
    required String title,
    required Map<String, dynamic> reportData,
    required String reportType,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(
            font: await PdfGoogleFonts.robotoRegular(),
            fontSize: 12,
          ),
        ),
        header: (context) => _buildHeader(context, title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildReportSummary(reportData, reportType),
          pw.SizedBox(height: 20),
          _buildReportDetails(reportData, reportType),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(pw.Context context, String title) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ZAZA ASSET MANAGEMENT SYSTEM',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _buildReportSummary(Map<String, dynamic> data, String reportType) {
    switch (reportType) {
      case 'users':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'User Report Summary',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Total Users', data['total']?.toString() ?? '0'),
                _buildStatCard(
                  'Active Users',
                  data['active']?.toString() ?? '0',
                ),
                _buildStatCard(
                  'Inactive Users',
                  data['inactive']?.toString() ?? '0',
                ),
              ],
            ),
          ],
        );
      case 'assets':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Asset Report Summary',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'Total Assets',
                  data['total']?.toString() ?? '0',
                ),
                _buildStatCard(
                  'Available',
                  data['available']?.toString() ?? '0',
                ),
                _buildStatCard('In Use', data['inUse']?.toString() ?? '0'),
                _buildStatCard(
                  'Total Value',
                  '\$${data['totalValue']?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ],
            ),
          ],
        );
      case 'borrowings':
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Borrowing Report Summary',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'Total Borrowings',
                  data['total']?.toString() ?? '0',
                ),
                _buildStatCard('Active', data['active']?.toString() ?? '0'),
                _buildStatCard('Pending', data['pending']?.toString() ?? '0'),
                _buildStatCard('Overdue', data['overdue']?.toString() ?? '0'),
              ],
            ),
          ],
        );
      default:
        return pw.Text('Summary not available');
    }
  }

  pw.Widget _buildStatCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportDetails(Map<String, dynamic> data, String reportType) {
    final List<Map<String, dynamic>> recentData =
        (data['recent'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (recentData.isEmpty) {
      return pw.Text('No detailed data available');
    }

    // Get headers from first item
    final headers = recentData.isNotEmpty ? recentData.first.keys.toList() : [];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: recentData.map((item) {
        return headers.map((header) {
          final value = item[header];
          if (value is DateTime) {
            return DateFormat('yyyy-MM-dd').format(value);
          }
          return value?.toString() ?? '';
        }).toList();
      }).toList(),
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(4),
    );
  }
}
