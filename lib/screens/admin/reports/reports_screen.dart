// lib/screens/admin/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/cyberpunk_theme.dart';
import 'report_service.dart';
import 'widgets/quick_stats_widget.dart';
import 'tabs/user_report_tab.dart';
import 'tabs/asset_report_tab.dart';
import 'tabs/borrowing_report_tab.dart';
import 'tabs/activity_report_tab.dart';
import 'export_service.dart';
import 'widgets/filter_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final ExportService _exportService = ExportService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      _stats = await _reportService.getAllStatistics(filters: _filters);
    } catch (e) {
      debugPrint('Error loading report data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showFilterDialog() async {
    final filters = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(currentFilters: _filters),
    );

    if (filters != null) {
      setState(() {
        _filters = filters;
      });
      _loadReportData();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
          const SizedBox(height: 20),
          Text(
            'Loading analytics...',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _exportReports(String format) {
    if (format == 'csv') {
      // Export user report
      if (_stats['users'] != null &&
          (_stats['users']['recent'] as List).isNotEmpty) {
        _exportService.exportToCSV(
          context: context,
          fileName: 'user_report',
          data: (_stats['users']['recent'] as List)
              .cast<Map<String, dynamic>>(),
        );
      }

      // Export asset report
      if (_stats['assets'] != null &&
          (_stats['assets']['recent'] as List).isNotEmpty) {
        _exportService.exportToCSV(
          context: context,
          fileName: 'asset_report',
          data: (_stats['assets']['recent'] as List)
              .cast<Map<String, dynamic>>(),
        );
      }

      // Export borrowing report
      if (_stats['borrowings'] != null &&
          (_stats['borrowings']['recent'] as List).isNotEmpty) {
        _exportService.exportToCSV(
          context: context,
          fileName: 'borrowing_report',
          data: (_stats['borrowings']['recent'] as List)
              .cast<Map<String, dynamic>>(),
        );
      }
    } else if (format == 'pdf') {
      // Export user report
      if (_stats['users'] != null) {
        _exportService.exportToPDF(
          context: context,
          title: 'User Report',
          data: _stats['users'],
          reportType: 'users',
        );
      }

      // Export asset report
      if (_stats['assets'] != null) {
        _exportService.exportToPDF(
          context: context,
          title: 'Asset Report',
          data: _stats['assets'],
          reportType: 'assets',
        );
      }

      // Export borrowing report
      if (_stats['borrowings'] != null) {
        _exportService.exportToPDF(
          context: context,
          title: 'Borrowing Report',
          data: _stats['borrowings'],
          reportType: 'borrowings',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [CyberpunkTheme.cardDark, CyberpunkTheme.deepBlack],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryPink.withAlpha(77),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: CyberpunkTheme.primaryPink,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'REPORTS & ANALYTICS',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CyberpunkTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),

                // Filter button
                if (_filters.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.primaryCyan.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 12,
                          color: CyberpunkTheme.primaryCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_filters.length} filter${_filters.length > 1 ? 's' : ''}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            color: CyberpunkTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),

                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: CyberpunkTheme.neonGreen,
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'Apply filters',
                ),
                const SizedBox(width: 8),

                // Refresh button
                IconButton(
                  icon: Icon(Icons.refresh, color: CyberpunkTheme.primaryCyan),
                  onPressed: _loadReportData,
                  tooltip: 'Refresh data',
                ),

                // Export button
                PopupMenuButton<String>(
                  icon: Icon(Icons.download, color: CyberpunkTheme.primaryPink),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'csv',
                      child: Text('Export as CSV'),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Text('Export as PDF'),
                    ),
                  ],
                  onSelected: _exportReports,
                ),
              ],
            ),
          ),

          // QUICK STATS
          if (!_isLoading && _stats.isNotEmpty) QuickStatsWidget(stats: _stats),

          // TABS
          Container(
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: CyberpunkTheme.primaryPink.withAlpha(77),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 11),
              labelColor: CyberpunkTheme.primaryPink,
              unselectedLabelColor: CyberpunkTheme.textMuted,
              indicatorColor: CyberpunkTheme.primaryPink,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'USER REPORTS'),
                Tab(text: 'ASSET REPORTS'),
                Tab(text: 'BORROWING REPORTS'),
                Tab(text: 'ACTIVITY LOGS'),
              ],
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // USER REPORTS TAB
                _isLoading
                    ? _buildLoading()
                    : UserReportTab(stats: _stats['users'] ?? {}),

                // ASSET REPORTS TAB
                _isLoading
                    ? _buildLoading()
                    : AssetReportTab(stats: _stats['assets'] ?? {}),

                // BORROWING REPORTS TAB
                _isLoading
                    ? _buildLoading()
                    : BorrowingReportTab(stats: _stats['borrowings'] ?? {}),

                // ACTIVITY LOGS TAB
                _isLoading
                    ? _buildLoading()
                    : ActivityReportTab(stats: _stats['activities'] ?? {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
