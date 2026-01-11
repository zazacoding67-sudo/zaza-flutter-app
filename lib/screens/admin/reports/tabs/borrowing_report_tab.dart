// lib/screens/admin/reports/tabs/borrowing_report_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';
import '../export_service.dart';
import '../widgets/report_charts_widget.dart';
import '../widgets/data_table_widget.dart';
import '../type_helpers.dart';

class BorrowingReportTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final ExportService _exportService = ExportService();

  BorrowingReportTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final borrowings = (stats['recent'] as List?) ?? [];
    final monthlyData = (stats['monthlyTrends'] as List?) ?? [];
    //final byStatus = (stats['byStatus'] as Map<String, dynamic>?) ?? {};

    // Convert data to proper types
    final List<Map<String, dynamic>> borrowingList =
        TypeHelpers.convertToListOfMaps(borrowings);
    final List<Map<String, dynamic>> monthlyList =
        TypeHelpers.convertToListOfMaps(monthlyData);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // BORROWING TRENDS CHART
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberpunkTheme.primaryCyan.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Borrowing Trends',
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: CyberpunkTheme.primaryCyan,
                        ),
                        onPressed: () => _exportService.exportToCSV(
                          context: context,
                          fileName: 'borrowing_report',
                          data: borrowingList,
                        ),
                      ),
                      // Change this line in the build method:
                      IconButton(
                        icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _exportService.exportToPDF(
                          context: context,
                          title: 'Borrowing Report',
                          data: stats,
                          reportType: 'borrowings',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ReportChartsWidget.buildMonthlyLineChart(
                      monthlyList,
                    ),
                  ),
                ],
              ),
            ),

            // RECENT BORROWINGS TABLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberpunkTheme.neonGreen.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Borrowings (${borrowingList.length})',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (borrowingList.isEmpty)
                    _buildEmptyState('No borrowings found')
                  else
                    DataTableWidget.buildBorrowingTable(borrowingList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.rajdhani(color: CyberpunkTheme.textMuted),
      ),
    );
  }
}
