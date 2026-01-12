// lib/screens/staff/staff_statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/staff_service.dart';

class StaffStatisticsScreen extends StatefulWidget {
  const StaffStatisticsScreen({super.key});

  @override
  State<StaffStatisticsScreen> createState() => _StaffStatisticsScreenState();
}

class _StaffStatisticsScreenState extends State<StaffStatisticsScreen> {
  final StaffService _staffService = StaffService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _staffService.getStaffStatistics();
      setState(() => _stats = stats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: CyberpunkTheme.warningYellow,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.surfaceDark,
        title: Text(
          'OPERATIONAL STATISTICS',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: CyberpunkTheme.primaryCyan,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              color: CyberpunkTheme.primaryCyan,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOperationalMetrics(),
                    const SizedBox(height: 20),
                    _buildAssetDistribution(),
                    const SizedBox(height: 20),
                    _buildBorrowingTrends(),
                    const SizedBox(height: 20),
                    _buildCategoryBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOperationalMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPERATIONAL METRICS',
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CyberpunkTheme.primaryCyan,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Pending',
                _stats['pendingRequests']?.toString() ?? '0',
                Icons.pending_actions,
                CyberpunkTheme.primaryPink,
                subtitle: 'Requests',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Active',
                _stats['activeBorrowings']?.toString() ?? '0',
                Icons.sync,
                CyberpunkTheme.primaryCyan,
                subtitle: 'Borrowings',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Overdue',
                _stats['overdueItems']?.toString() ?? '0',
                Icons.warning,
                CyberpunkTheme.warningYellow,
                subtitle: 'Items',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Due Today',
                _stats['todayReturns']?.toString() ?? '0',
                Icons.today,
                CyberpunkTheme.neonGreen,
                subtitle: 'Returns',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'This Week',
                _stats['weeklyApprovals']?.toString() ?? '0',
                Icons.check_circle,
                CyberpunkTheme.neonGreen,
                subtitle: 'Approvals',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'This Month',
                _stats['monthlyReturns']?.toString() ?? '0',
                Icons.assignment_return,
                CyberpunkTheme.primaryCyan,
                subtitle: 'Returns',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: CyberpunkTheme.textMuted,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.rajdhani(
                fontSize: 10,
                color: CyberpunkTheme.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetDistribution() {
    final total = _stats['totalAssets'] ?? 0;
    final available = _stats['availableAssets'] ?? 0;
    final inUse = _stats['inUseAssets'] ?? 0;
    final maintenance = _stats['maintenanceAssets'] ?? 0;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.primaryCyan.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSET DISTRIBUTION',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryCyan,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: available.toDouble(),
                    title: '$available',
                    color: CyberpunkTheme.neonGreen,
                    radius: 60,
                    titleStyle: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.deepBlack,
                    ),
                  ),
                  PieChartSectionData(
                    value: inUse.toDouble(),
                    title: '$inUse',
                    color: CyberpunkTheme.primaryCyan,
                    radius: 60,
                    titleStyle: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.deepBlack,
                    ),
                  ),
                  PieChartSectionData(
                    value: maintenance.toDouble(),
                    title: '$maintenance',
                    color: CyberpunkTheme.warningYellow,
                    radius: 60,
                    titleStyle: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CyberpunkTheme.deepBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend([
            ('Available', CyberpunkTheme.neonGreen, available),
            ('In Use', CyberpunkTheme.primaryCyan, inUse),
            ('Maintenance', CyberpunkTheme.warningYellow, maintenance),
          ], total),
        ],
      ),
    );
  }

  Widget _buildBorrowingTrends() {
    final pending = _stats['pendingRequests'] ?? 0;
    final active = _stats['activeBorrowings'] ?? 0;
    final overdue = _stats['overdueItems'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.primaryPink.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BORROWING STATUS',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryPink,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    [
                      pending,
                      active,
                      overdue,
                    ].reduce((a, b) => a > b ? a : b).toDouble() +
                    2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['Pending', 'Active', 'Overdue'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: GoogleFonts.rajdhani(
                              color: CyberpunkTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.rajdhani(
                            color: CyberpunkTheme.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: CyberpunkTheme.textMuted.withAlpha(51),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: pending.toDouble(),
                        color: CyberpunkTheme.primaryPink,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: active.toDouble(),
                        color: CyberpunkTheme.primaryCyan,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: overdue.toDouble(),
                        color: CyberpunkTheme.warningYellow,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryBreakdown =
        _stats['categoryBreakdown'] as Map<String, dynamic>? ?? {};

    if (categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberpunkTheme.neonGreen.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY BREAKDOWN',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.neonGreen,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryBreakdown.entries.map((entry) {
            final category = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final total = data['total'] ?? 0;
            final available = data['available'] ?? 0;
            final percentage = total > 0
                ? (available / total * 100).toInt()
                : 0;

            return _buildCategoryRow(category, total, available, percentage);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String category,
    int total,
    int available,
    int percentage,
  ) {
    Color statusColor;
    if (percentage >= 50) {
      statusColor = CyberpunkTheme.neonGreen;
    } else if (percentage >= 25) {
      statusColor = CyberpunkTheme.warningYellow;
    } else {
      statusColor = CyberpunkTheme.primaryPink;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textPrimary,
                ),
              ),
              Text(
                '$available / $total available',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: CyberpunkTheme.textMuted.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% available',
            style: GoogleFonts.rajdhani(fontSize: 10, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<(String, Color, int)> items, int total) {
    return Column(
      children: items.map((item) {
        final (label, color, value) = item;
        final percentage = total > 0 ? (value / total * 100).toInt() : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      color: CyberpunkTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '$value ($percentage%)',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CyberpunkTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
