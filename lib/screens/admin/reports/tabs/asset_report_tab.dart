// lib/screens/admin/reports/tabs/asset_report_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';
import '../export_service.dart';
import '../widgets/report_charts_widget.dart';
import '../widgets/data_table_widget.dart';
import '../type_helpers.dart';

class AssetReportTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final ExportService _exportService = ExportService();

  AssetReportTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final assets = (stats['recent'] as List?) ?? [];
    final byCategory = (stats['byCategory'] as Map<String, dynamic>?) ?? {};
    //final byStatus = (stats['byStatus'] as Map<String, dynamic>?) ?? {};

    // Convert assets to proper type
    final List<Map<String, dynamic>> assetList =
        TypeHelpers.convertToListOfMaps(assets);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ASSET DISTRIBUTION CHARTS
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
                        'Asset Distribution',
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
                          fileName: 'asset_report',
                          data: assetList,
                        ),
                      ),
                      // Change this line in the build method:
                      IconButton(
                        icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _exportService.exportToPDF(
                          context: context,
                          title: 'Asset Report',
                          data: stats,
                          reportType: 'assets',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: ReportChartsWidget.buildCategoryBarChart(byCategory),
                  ),
                ],
              ),
            ),

            // RECENT ASSETS TABLE
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
                    'Recent Assets (${assetList.length})',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (assetList.isEmpty)
                    _buildEmptyState('No assets found')
                  else
                    DataTableWidget.buildAssetTable(assetList),
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
