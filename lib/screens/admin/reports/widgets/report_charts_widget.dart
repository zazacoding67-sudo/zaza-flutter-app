// lib/screens/admin/reports/widgets/report_charts_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/cyberpunk_theme.dart';

class ReportChartsWidget {
  // Role Pie Chart using fl_chart
  static Widget buildRolePieChart(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No role data available');
    }

    final pieChartSections = data.entries.map((entry) {
      final color = _getRoleChartColor(entry.key);
      return PieChartSectionData(
        color: color,
        value: (entry.value as num?)?.toDouble() ?? 0,
        title: '${entry.key}\n${entry.value}',
        radius: 60,
        titleStyle: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: pieChartSections,
      ),
    );
  }

  // Category Bar Chart using fl_chart - FIXED LABELS
  static Widget buildCategoryBarChart(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No category data available');
    }

    // Calculate max value for Y-axis
    final maxValue = data.values.fold<double>(0, (max, value) {
      final numValue = (value as num?)?.toDouble() ?? 0;
      return numValue > max ? numValue : max;
    });

    // Ensure maxY is at least 1 and add some padding
    final maxY = (maxValue + 1).ceilToDouble();

    final barGroups = data.entries.map((entry) {
      final value = (entry.value as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: data.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: value,
            color: CyberpunkTheme.neonGreen,
            width: 20,
            borderRadius: BorderRadius.circular(4),
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
                if (index >= 0 && index < data.keys.length) {
                  final category = data.keys.elementAt(index);
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
              final category = data.keys.elementAt(group.x.toInt());
              final count = rod.toY.toInt();
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
  }

  // Monthly Line Chart using fl_chart
  static Widget buildMonthlyLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No monthly data available');
    }

    // Sort data by month for proper ordering
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) {
        final monthA = a['month']?.toString() ?? '';
        final monthB = b['month']?.toString() ?? '';
        return monthA.compareTo(monthB);
      });

    final spots = sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return FlSpot(index.toDouble(), (item['count'] as num?)?.toDouble() ?? 0);
    }).toList();

    // Calculate max value for Y-axis
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
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
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
      ),
    );
  }

  // Activity Chart (additional chart)
  static Widget buildActivityChart(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return _buildPlaceholder('No activity data available');
    }

    // Calculate max value for Y-axis
    final maxValue = data.values.fold<double>(0, (max, value) {
      final numValue = (value as num?)?.toDouble() ?? 0;
      return numValue > max ? numValue : max;
    });

    final maxY = (maxValue + 1).ceilToDouble();

    final barGroups = data.entries.map((entry) {
      return BarChartGroupData(
        x: data.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: (entry.value as num?)?.toDouble() ?? 0,
            color: CyberpunkTheme.primaryCyan,
            width: 12,
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.keys.length) {
                  final key = data.keys.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      key.length > 8 ? '${key.substring(0, 8)}..' : key,
                      style: GoogleFonts.rajdhani(fontSize: 9),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY <= 5 ? 1 : (maxY / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.rajdhani(fontSize: 10),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for placeholder
  static Widget _buildPlaceholder(String message) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Text(
        message,
        style: GoogleFonts.rajdhani(
          color: CyberpunkTheme.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }

  // Color helper for role chart
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
