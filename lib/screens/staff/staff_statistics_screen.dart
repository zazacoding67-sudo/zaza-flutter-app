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
      if (mounted) setState(() => _stats = stats);
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
      if (mounted) setState(() => _isLoading = false);
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: CyberpunkTheme.primaryCyan),
                  const SizedBox(height: 20),
                  Text(
                    'Loading statistics...',
                    style: GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              color: CyberpunkTheme.primaryCyan,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                cacheExtent: 10,
                itemCount: 4,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return OperationalMetricsWidget(stats: _stats);
                    case 1:
                      return AssetDistributionWidget(stats: _stats);
                    case 2:
                      return BorrowingTrendsWidget(stats: _stats);
                    case 3:
                      return CategoryBreakdownWidget(stats: _stats);
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Operational Metrics Widget
// ---------------------------------------------------------------------------
class OperationalMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const OperationalMetricsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
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
        _buildRow(
          'Pending',
          stats['pendingRequests']?.toString() ?? '0',
          Icons.pending_actions,
          CyberpunkTheme.primaryPink,
          'Active',
          stats['activeBorrowings']?.toString() ?? '0',
          Icons.sync,
          CyberpunkTheme.primaryCyan,
          'Requests',
          'Borrowings',
        ),
        const SizedBox(height: 12),
        _buildRow(
          'Overdue',
          stats['overdueItems']?.toString() ?? '0',
          Icons.warning,
          CyberpunkTheme.warningYellow,
          'Due Today',
          stats['todayReturns']?.toString() ?? '0',
          Icons.today,
          CyberpunkTheme.neonGreen,
          'Items',
          'Returns',
        ),
        const SizedBox(height: 12),
        _buildRow(
          'This Week',
          stats['weeklyApprovals']?.toString() ?? '0',
          Icons.check_circle,
          CyberpunkTheme.neonGreen,
          'This Month',
          stats['monthlyReturns']?.toString() ?? '0',
          Icons.assignment_return,
          CyberpunkTheme.primaryCyan,
          'Approvals',
          'Returns',
        ),
      ],
    );
  }

  Widget _buildRow(
    String l1,
    String v1,
    IconData i1,
    Color c1,
    String l2,
    String v2,
    IconData i2,
    Color c2,
    String s1,
    String s2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: l1,
            value: v1,
            icon: i1,
            color: c1,
            subtitle: s1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: l2,
            value: v2,
            icon: i2,
            color: c2,
            subtitle: s2,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.8, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.scale(scale: val, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(26),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
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
                subtitle!,
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Asset Distribution Widget - ONLY ROTATING (No Pop Up)
// ---------------------------------------------------------------------------
class AssetDistributionWidget extends StatefulWidget {
  final Map<String, dynamic> stats;
  const AssetDistributionWidget({super.key, required this.stats});

  @override
  State<AssetDistributionWidget> createState() =>
      _AssetDistributionWidgetState();
}

class _AssetDistributionWidgetState extends State<AssetDistributionWidget>
    with SingleTickerProviderStateMixin {
  int _touchedPieIndex = -1;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Continuous slow rotation loop
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.stats['totalAssets'] ?? 0;
    final available = widget.stats['availableAssets'] ?? 0;
    final inUse = widget.stats['inUseAssets'] ?? 0;
    final maintenance = widget.stats['maintenanceAssets'] ?? 0;

    if (total == 0) return const SizedBox.shrink();

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
            // Just the rotation animation, no size scaling
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                final rotationOffset = _rotationController.value * 360;

                return PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    // Only continuous rotation
                    startDegreeOffset: rotationOffset,
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      _buildSection(
                        available,
                        total,
                        CyberpunkTheme.neonGreen,
                        0,
                      ),
                      _buildSection(
                        inUse,
                        total,
                        CyberpunkTheme.primaryCyan,
                        1,
                      ),
                      _buildSection(
                        maintenance,
                        total,
                        CyberpunkTheme.warningYellow,
                        2,
                      ),
                    ],
                  ),
                  swapAnimationDuration: Duration.zero,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _Legend(
            items: [
              ('Available', CyberpunkTheme.neonGreen, available),
              ('In Use', CyberpunkTheme.primaryCyan, inUse),
              ('Maintenance', CyberpunkTheme.warningYellow, maintenance),
            ],
            total: total,
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(
    int value,
    int total,
    Color color,
    int index,
  ) {
    final isTouched = index == _touchedPieIndex;
    final fontSize = isTouched ? 18.0 : 14.0;
    final radius = isTouched ? 90.0 : 60.0;

    return PieChartSectionData(
      value: value.toDouble(),
      title: '$value',
      color: color,
      radius: radius,
      titleStyle: GoogleFonts.rajdhani(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: CyberpunkTheme.deepBlack,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Borrowing Trends Widget - INCREASE ANIMATION (Bars growing up)
// ---------------------------------------------------------------------------
class BorrowingTrendsWidget extends StatefulWidget {
  final Map<String, dynamic> stats;
  const BorrowingTrendsWidget({super.key, required this.stats});

  @override
  State<BorrowingTrendsWidget> createState() => _BorrowingTrendsWidgetState();
}

class _BorrowingTrendsWidgetState extends State<BorrowingTrendsWidget> {
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    final pending = widget.stats['pendingRequests'] ?? 0;
    final active = widget.stats['activeBorrowings'] ?? 0;
    final overdue = widget.stats['overdueItems'] ?? 0;

    double fixedMaxY = 10;
    if (pending > 0 || active > 0 || overdue > 0) {
      fixedMaxY =
          [
            pending,
            active,
            overdue,
          ].reduce((a, b) => a > b ? a : b).toDouble() +
          5;
    }

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
            // "Increase" Animation: Bars grow smoothly from 0 height to full height
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2000),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutQuart, // Smooth, strong increase curve
              builder: (context, progress, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: fixedMaxY,
                    barTouchData: BarTouchData(
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              barTouchResponse == null ||
                              barTouchResponse.spot == null) {
                            _touchedBarIndex = -1;
                            return;
                          }
                          _touchedBarIndex =
                              barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final labels = ['Pending', 'Active', 'Overdue'];
                            if (value < 0 || value >= labels.length)
                              return const SizedBox();
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
                            if (value % 1 != 0) return const SizedBox();
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
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: CyberpunkTheme.textMuted.withAlpha(51),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _buildBarGroup(
                        0,
                        pending,
                        fixedMaxY,
                        CyberpunkTheme.primaryPink,
                        progress,
                      ),
                      _buildBarGroup(
                        1,
                        active,
                        fixedMaxY,
                        CyberpunkTheme.primaryCyan,
                        progress,
                      ),
                      _buildBarGroup(
                        2,
                        overdue,
                        fixedMaxY,
                        CyberpunkTheme.warningYellow,
                        progress,
                      ),
                    ],
                  ),
                  swapAnimationDuration: Duration.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    int value,
    double maxY,
    Color color,
    double progress,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (value * progress).toDouble(),
          color: color,
          width: _touchedBarIndex == x ? 55 : 45,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: CyberpunkTheme.deepBlack,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Category Breakdown Widget - Keep As Is
// ---------------------------------------------------------------------------
class CategoryBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  const CategoryBreakdownWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final categoryBreakdown =
        stats['categoryBreakdown'] as Map<String, dynamic>? ?? {};
    if (categoryBreakdown.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.7, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: ((value - 0.7) * 3.3).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
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
              return _CategoryRow(
                category: category,
                total: total,
                available: available,
                percentage: percentage,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int total;
  final int available;
  final int percentage;

  const _CategoryRow({
    required this.category,
    required this.total,
    required this.available,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
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
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 2200),
            tween: Tween(begin: 0.0, end: percentage / 100),
            curve: Curves.easeOutQuint,
            builder: (context, progress, child) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.textMuted.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withAlpha(77),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
}

class _Legend extends StatelessWidget {
  final List<(String, Color, int)> items;
  final int total;

  const _Legend({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
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
                      boxShadow: [
                        BoxShadow(color: color.withAlpha(77), blurRadius: 4),
                      ],
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
