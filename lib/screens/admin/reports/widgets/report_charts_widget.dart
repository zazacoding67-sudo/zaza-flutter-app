// lib/screens/admin/reports/widgets/report_charts_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';

class ReportChartsWidget {
  // ==================== ANIMATED PIE CHART FOR ROLES ====================
  static Widget buildRolePieChart(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No role data available');
    }

    return _AnimatedPieChart(data: data);
  }

  // ==================== ANIMATED BAR CHART FOR CATEGORIES ====================
  static Widget buildCategoryBarChart(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No category data available');
    }

    return _AnimatedBarChart(data: data);
  }

  // ==================== ANIMATED LINE CHART FOR MONTHLY TRENDS ====================
  static Widget buildMonthlyLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No monthly data available');
    }

    return _AnimatedLineChart(data: data);
  }

  // ==================== PLACEHOLDER ====================
  static Widget _buildPlaceholder(String message) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: CyberpunkTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COLOR HELPERS ====================
  static Color _getRoleChartColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return CyberpunkTheme.primaryPink;
      case 'staff':
        return CyberpunkTheme.primaryCyan;
      case 'student':
        return CyberpunkTheme.neonGreen;
      default:
        return CyberpunkTheme.primaryPurple;
    }
  }
}

// ==================== ANIMATED PIE CHART ====================
class _AnimatedPieChart extends StatefulWidget {
  final Map<String, dynamic> data;

  const _AnimatedPieChart({required this.data});

  @override
  State<_AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<_AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pieChartSections = widget.data.entries.map((entry) {
          final isTouched =
              widget.data.keys.toList().indexOf(entry.key) == touchedIndex;
          final color = ReportChartsWidget._getRoleChartColor(entry.key);
          final value = (entry.value as num?)?.toDouble() ?? 0;
          final animatedValue = value * _animation.value;

          return PieChartSectionData(
            color: color,
            value: animatedValue,
            title: '${entry.key}\n${entry.value}',
            radius: isTouched ? 70 : 60,
            titleStyle: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          );
        }).toList();

        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: pieChartSections,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
          ),
        );
      },
    );
  }
}

// ==================== ANIMATED BAR CHART ====================
class _AnimatedBarChart extends StatefulWidget {
  final Map<String, dynamic> data;

  const _AnimatedBarChart({required this.data});

  @override
  State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.data.values.fold<double>(0, (max, value) {
      final numValue = (value as num?)?.toDouble() ?? 0;
      return numValue > max ? numValue : max;
    });

    final maxY = (maxValue + 1).ceilToDouble();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final barGroups = widget.data.entries.map((entry) {
          final value = (entry.value as num?)?.toDouble() ?? 0;
          final animatedValue = value * _animation.value;

          return BarChartGroupData(
            x: widget.data.keys.toList().indexOf(entry.key),
            barRods: [
              BarChartRodData(
                toY: animatedValue,
                color: CyberpunkTheme.neonGreen,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    CyberpunkTheme.neonGreen.withOpacity(0.5),
                    CyberpunkTheme.neonGreen,
                  ],
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: CyberpunkTheme.surfaceDark.withAlpha(51),
                ),
              ),
            ],
          );
        }).toList();

        return BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barGroups: barGroups,
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: CyberpunkTheme.textMuted.withAlpha(77),
                width: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  'Asset Categories',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < widget.data.keys.length) {
                      final category = widget.data.keys.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          category,
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            color: CyberpunkTheme.textPrimary,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(
                  'Number of Assets',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY <= 5 ? 1 : (maxY / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const Text('');
                    }
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: CyberpunkTheme.textMuted.withAlpha(25),
                  strokeWidth: 1,
                );
              },
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => CyberpunkTheme.surfaceDark,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final category = widget.data.keys.elementAt(group.x.toInt());
                  final count = widget.data.values.elementAt(group.x.toInt());
                  return BarTooltipItem(
                    '$category\n$count ${count == 1 ? 'item' : 'items'}',
                    GoogleFonts.rajdhani(
                      color: CyberpunkTheme.textPrimary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== ANIMATED LINE CHART ====================
class _AnimatedLineChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const _AnimatedLineChart({required this.data});

  @override
  State<_AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<_AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = List<Map<String, dynamic>>.from(widget.data)
      ..sort((a, b) {
        final monthA = a['month']?.toString() ?? '';
        final monthB = b['month']?.toString() ?? '';
        return monthA.compareTo(monthB);
      });

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final spots = sortedData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final value = (item['count'] as num?)?.toDouble() ?? 0;
          final animatedValue = value * _animation.value;
          return FlSpot(index.toDouble(), animatedValue);
        }).toList();

        final maxValue = spots.fold<double>(
          0,
          (max, spot) => spot.y > max ? spot.y : max,
        );
        final maxY = (maxValue + 1).ceilToDouble();

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: CyberpunkTheme.primaryPink,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: CyberpunkTheme.primaryPink,
                      strokeWidth: 2,
                      strokeColor: CyberpunkTheme.deepBlack,
                    );
                  },
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                gradient: LinearGradient(
                  colors: [
                    CyberpunkTheme.primaryPink.withOpacity(0.5),
                    CyberpunkTheme.primaryPink,
                  ],
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CyberpunkTheme.primaryPink.withOpacity(0.3),
                      CyberpunkTheme.primaryPink.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  'Months',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedData.length) {
                      return Text(
                        sortedData[index]['month']?.toString() ?? '',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(
                  'Number of Borrowings',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: CyberpunkTheme.textPrimary,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY <= 5 ? 1 : (maxY / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const Text('');
                    }
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        color: CyberpunkTheme.textPrimary,
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: CyberpunkTheme.textMuted.withAlpha(25),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: CyberpunkTheme.textMuted.withAlpha(77),
                width: 1,
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => CyberpunkTheme.surfaceDark,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final month = sortedData[spot.x.toInt()]['month'];
                    final count = sortedData[spot.x.toInt()]['count'];
                    return LineTooltipItem(
                      '$month\n$count borrowings',
                      GoogleFonts.rajdhani(
                        color: CyberpunkTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
