// lib/screens/admin/reports/tabs/activity_report_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';
import '../export_service.dart';
import '../type_helpers.dart';

class ActivityReportTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final ExportService _exportService = ExportService();

  ActivityReportTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final activities = (stats['recent'] as List?) ?? [];

    // Convert activities to proper type
    final List<Map<String, dynamic>> activityList =
        TypeHelpers.convertToListOfMaps(activities);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ACTIVITY LOGS
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Activity Logs',
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
                          fileName: 'activity_log',
                          data: activityList,
                        ),
                      ),
                      // Change this line in the build method:
                      IconButton(
                        icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _exportService.exportToPDF(
                          context: context,
                          title: 'Activity Report',
                          data: stats,
                          reportType: 'activities',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activityList.isEmpty)
                    _buildEmptyState('No activities found')
                  else
                    _buildActivityList(activityList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> activities) {
    return Column(
      children: activities.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CyberpunkTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CyberpunkTheme.primaryPurple.withAlpha(51),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(activity['action']?.toString() ?? ''),
                color: _getActivityColor(activity['action']?.toString() ?? ''),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['action']?.toString() ?? 'Unknown Action',
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'By: ${activity['performedByName'] ?? 'System'}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getActivityIcon(String action) {
    if (action.contains('create')) return Icons.add_circle;
    if (action.contains('update')) return Icons.edit;
    if (action.contains('delete')) return Icons.delete;
    if (action.contains('login')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    if (action.contains('borrow')) return Icons.arrow_upward;
    if (action.contains('return')) return Icons.arrow_downward;
    return Icons.history;
  }

  Color _getActivityColor(String action) {
    if (action.contains('create')) return CyberpunkTheme.neonGreen;
    if (action.contains('update')) return CyberpunkTheme.primaryCyan;
    if (action.contains('delete')) return Colors.red;
    if (action.contains('login')) return Colors.green;
    if (action.contains('logout')) return Colors.orange;
    return CyberpunkTheme.primaryPurple;
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
