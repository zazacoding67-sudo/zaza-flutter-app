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
      final pdf = await _generateProfessionalReportPDF(
        title: title,
        reportData: reportData,
        reportType: reportType,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name:
            '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('PDF exported successfully: $title'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to export PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generateProfessionalReportPDF({
    required String title,
    required Map<String, dynamic> reportData,
    required String reportType,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Load custom fonts for professional look
    final boldFont = await PdfGoogleFonts.robotoMedium();
    final regularFont = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Cover Page Header
          _buildProfessionalHeader(title, now, boldFont, regularFont),
          pw.SizedBox(height: 30),

          // Executive Summary
          _buildExecutiveSummary(reportData, reportType, boldFont, regularFont),
          pw.SizedBox(height: 30),

          // Key Metrics Cards
          _buildKeyMetrics(reportData, reportType, boldFont, regularFont),
          pw.SizedBox(height: 30),

          // Detailed Data Table
          _buildDetailedDataSection(
            reportData,
            reportType,
            boldFont,
            regularFont,
          ),
        ],
        footer: (context) =>
            _buildProfessionalFooter(context, now, regularFont),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      ),
    );

    return pdf;
  }

  // ==================== PROFESSIONAL HEADER ====================
  pw.Widget _buildProfessionalHeader(
    String title,
    DateTime now,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF1E3A8A), PdfColor.fromInt(0xFF3B82F6)],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo and Title Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Logo + Company Name
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo Box
                  _buildLogo(boldFont),
                  pw.SizedBox(width: 16),
                  // Company Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ASSET MANAGEMENT SYSTEM',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: const PdfColor.fromInt(0xFFB3B3B3),
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 24,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right side: Official Badge
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'OFFICIAL\nREPORT',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: const PdfColor.fromInt(0xFF4D4D4D), thickness: 1),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                'Generated',
                DateFormat('MMMM dd, yyyy').format(now),
                regularFont,
              ),
              _buildInfoItem(
                'Time',
                DateFormat('HH:mm:ss').format(now),
                regularFont,
              ),
              _buildInfoItem('Status', 'Confidential', regularFont),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== LOGO BUILDER ====================
  pw.Widget _buildLogo(pw.Font boldFont) {
    // Simple text-based logo badge
    return pw.Container(
      width: 60,
      height: 60,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFF3B82F6),
          width: 2,
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'AMS',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 18,
                color: const PdfColor.fromInt(0xFF1E3A8A),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              width: 30,
              height: 2,
              color: const PdfColor.fromInt(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 8,
            color: const PdfColor.fromInt(0xFFB3B3B3),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
        ),
      ],
    );
  }

  // ==================== EXECUTIVE SUMMARY ====================
  pw.Widget _buildExecutiveSummary(
    Map<String, dynamic> data,
    String reportType,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: const PdfColor.fromInt(0xFF3B82F6),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            _getSummaryText(data, reportType),
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 11,
              color: const PdfColor.fromInt(0xFF475569),
              lineSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getSummaryText(Map<String, dynamic> data, String reportType) {
    switch (reportType) {
      case 'users':
        return 'This report provides a comprehensive overview of user management within the system. '
            'Currently, there are ${data['total'] ?? 0} registered users, with ${data['active'] ?? 0} active accounts. '
            'The user base is distributed across different roles, with detailed breakdowns available in the metrics section below.';
      case 'assets':
        return 'This asset management report summarizes the current state of organizational assets. '
            'The system manages ${data['total'] ?? 0} assets with a total value of \$${(data['totalValue'] ?? 0).toStringAsFixed(2)}. '
            'Currently, ${data['available'] ?? 0} assets are available for use, while ${data['inUse'] ?? 0} are in active deployment.';
      case 'borrowings':
        return 'This borrowing activity report tracks asset circulation and usage patterns. '
            'There are ${data['active'] ?? 0} active borrowings, with ${data['pending'] ?? 0} requests pending approval. '
            '${data['overdue'] ?? 0} items are currently overdue and require immediate attention.';
      default:
        return 'This report provides detailed analytics and insights for administrative review.';
    }
  }

  // ==================== KEY METRICS CARDS ====================
  pw.Widget _buildKeyMetrics(
    Map<String, dynamic> data,
    String reportType,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    List<_MetricCard> metrics = [];

    switch (reportType) {
      case 'users':
        metrics = [
          _MetricCard(
            'Total Users',
            '${data['total'] ?? 0}',
            PdfColors.blue,
            '👥',
          ),
          _MetricCard(
            'Active Users',
            '${data['active'] ?? 0}',
            PdfColors.green,
            '✓',
          ),
          _MetricCard(
            'Inactive Users',
            '${data['inactive'] ?? 0}',
            PdfColors.orange,
            '○',
          ),
          _MetricCard(
            'Admin Count',
            '${(data['byRole']?['admin'] ?? 0)}',
            PdfColors.purple,
            '⚡',
          ),
        ];
        break;
      case 'assets':
        metrics = [
          _MetricCard(
            'Total Assets',
            '${data['total'] ?? 0}',
            PdfColors.blue,
            '📦',
          ),
          _MetricCard(
            'Available',
            '${data['available'] ?? 0}',
            PdfColors.green,
            '✓',
          ),
          _MetricCard('In Use', '${data['inUse'] ?? 0}', PdfColors.orange, '⚙'),
          _MetricCard(
            'Total Value',
            '\$${(data['totalValue'] ?? 0).toStringAsFixed(0)}',
            PdfColors.teal,
            '💰',
          ),
        ];
        break;
      case 'borrowings':
        metrics = [
          _MetricCard(
            'Total Borrowings',
            '${data['total'] ?? 0}',
            PdfColors.blue,
            '📋',
          ),
          _MetricCard('Active', '${data['active'] ?? 0}', PdfColors.green, '⟳'),
          _MetricCard(
            'Pending',
            '${data['pending'] ?? 0}',
            PdfColors.orange,
            '⏱',
          ),
          _MetricCard('Overdue', '${data['overdue'] ?? 0}', PdfColors.red, '⚠'),
        ];
        break;
      default:
        metrics = [];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Performance Indicators',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: const PdfColor.fromInt(0xFF1E293B),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics
              .map((metric) => _buildMetricCard(metric, boldFont, regularFont))
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard(
    _MetricCard metric,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      width: 120,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Colored icon box at top
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: metric.color,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                metric.icon,
                style: pw.TextStyle(fontSize: 20, color: PdfColors.white),
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          // Large number value
          pw.Text(
            metric.value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 28,
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
          ),
          pw.SizedBox(height: 4),
          // Label text
          pw.Text(
            metric.label,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              color: const PdfColor.fromInt(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DETAILED DATA TABLE ====================
  pw.Widget _buildDetailedDataSection(
    Map<String, dynamic> data,
    String reportType,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    final List<Map<String, dynamic>> recentData =
        (data['recent'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (recentData.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(40),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No detailed data available',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 12,
            color: PdfColors.grey,
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Records',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 14,
            color: const PdfColor.fromInt(0xFF1E293B),
          ),
        ),
        pw.SizedBox(height: 16),
        _buildStyledTable(recentData, reportType, boldFont, regularFont),
      ],
    );
  }

  pw.Widget _buildStyledTable(
    List<Map<String, dynamic>> data,
    String reportType,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    // Define columns based on report type
    List<String> columns = _getTableColumns(reportType);

    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFE2E8F0),
        width: 1,
      ),
      columnWidths: _getColumnWidths(columns),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1E3A8A),
          ),
          children: columns
              .map(
                (col) => pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    col.toUpperCase(),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Data Rows
        ...data.take(20).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven
                  ? PdfColors.white
                  : const PdfColor.fromInt(0xFFF8FAFC),
            ),
            children: columns.map((col) {
              final value = _getFormattedValue(row, col, reportType);
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: const PdfColor.fromInt(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  List<String> _getTableColumns(String reportType) {
    switch (reportType) {
      case 'users':
        return ['Name', 'Email', 'Role', 'Status', 'Joined'];
      case 'assets':
        return ['Asset Name', 'Category', 'Status', 'Value', 'Location'];
      case 'borrowings':
        return ['Asset', 'User', 'Status', 'Requested', 'Due Date'];
      default:
        return ['ID', 'Description', 'Date'];
    }
  }

  Map<int, pw.TableColumnWidth> _getColumnWidths(List<String> columns) {
    final widths = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      widths[i] = const pw.FlexColumnWidth();
    }
    return widths;
  }

  String _getFormattedValue(
    Map<String, dynamic> row,
    String column,
    String reportType,
  ) {
    switch (reportType) {
      case 'users':
        switch (column) {
          case 'Name':
            return row['name']?.toString() ?? '-';
          case 'Email':
            return row['email']?.toString() ?? '-';
          case 'Role':
            return (row['role']?.toString() ?? '-').toUpperCase();
          case 'Status':
            return (row['status']?.toString() ?? '-').toUpperCase();
          case 'Joined':
            return row['createdAt'] is DateTime
                ? DateFormat('dd/MM/yyyy').format(row['createdAt'])
                : '-';
          default:
            return '-';
        }
      case 'assets':
        switch (column) {
          case 'Asset Name':
            return row['name']?.toString() ?? '-';
          case 'Category':
            return row['category']?.toString() ?? '-';
          case 'Status':
            return (row['status']?.toString() ?? '-').toUpperCase();
          case 'Value':
            return '\$${(row['value'] ?? 0).toStringAsFixed(2)}';
          case 'Location':
            return row['location']?.toString() ?? '-';
          default:
            return '-';
        }
      case 'borrowings':
        switch (column) {
          case 'Asset':
            return row['assetName']?.toString() ?? '-';
          case 'User':
            return row['userName']?.toString() ?? '-';
          case 'Status':
            return (row['status']?.toString() ?? '-').toUpperCase();
          case 'Requested':
            return row['requestedDate'] is DateTime
                ? DateFormat('dd/MM/yyyy').format(row['requestedDate'])
                : '-';
          case 'Due Date':
            return row['expectedReturnDate'] is DateTime
                ? DateFormat('dd/MM/yyyy').format(row['expectedReturnDate'])
                : '-';
          default:
            return '-';
        }
      default:
        return '-';
    }
  }

  // ==================== PROFESSIONAL FOOTER ====================
  pw.Widget _buildProfessionalFooter(
    pw.Context context,
    DateTime now,
    pw.Font regularFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Asset Management System © ${now.year}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'CONFIDENTIAL',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: PdfColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for metrics
class _MetricCard {
  final String label;
  final String value;
  final PdfColor color;
  final String icon;

  _MetricCard(this.label, this.value, this.color, this.icon);
}
