// lib/screens/admin/reports/tabs/user_report_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';
import '../export_service.dart';
import '../widgets/report_charts_widget.dart';
import '../widgets/data_table_widget.dart';
import '../type_helpers.dart';

class UserReportTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final ExportService _exportService = ExportService();

  UserReportTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final users = (stats['recent'] as List?) ?? [];
    final byRole = (stats['byRole'] as Map<String, dynamic>?) ?? {};

    // Convert users to proper type
    final List<Map<String, dynamic>> userList = TypeHelpers.convertToListOfMaps(
      users,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // USER DISTRIBUTION CHART
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberpunkTheme.primaryCyan.withAlpha(
                    77,
                  ), // 0.3 opacity
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'User Distribution by Role',
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
                          fileName: 'user_report',
                          data: userList,
                        ),
                      ),
                      // Change this line in the build method:
                      IconButton(
                        icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _exportService.exportToPDF(
                          context: context,
                          title: 'User Report',
                          data: stats,
                          reportType: 'users',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ReportChartsWidget.buildRolePieChart(byRole),
                  ),
                ],
              ),
            ),

            // RECENT USERS TABLE
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
                    'Recent Users (${userList.length})',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (userList.isEmpty)
                    _buildEmptyState('No users found')
                  else
                    DataTableWidget.buildUserTable(userList),
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
