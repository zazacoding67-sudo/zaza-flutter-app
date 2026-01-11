import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../theme/cyberpunk_theme.dart';

class QuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final userStats = stats['users'] as Map<String, dynamic>? ?? {};
    final assetStats = stats['assets'] as Map<String, dynamic>? ?? {};
    final borrowStats = stats['borrowings'] as Map<String, dynamic>? ?? {};
    final activityStats = stats['activities'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: CyberpunkTheme.primaryPink.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildStatCard(
            title: 'Total Users',
            value: '${userStats['total'] ?? 0}',
            change: '+${(userStats['total'] ?? 0) ~/ 10} this month',
            color: CyberpunkTheme.primaryCyan,
            icon: Icons.people,
          ),
          _buildStatCard(
            title: 'Total Assets',
            value: '${assetStats['total'] ?? 0}',
            change: '${assetStats['available'] ?? 0} available',
            color: CyberpunkTheme.neonGreen,
            icon: Icons.inventory,
          ),
          _buildStatCard(
            title: 'Active Loans',
            value: '${borrowStats['active'] ?? 0}',
            change: '${borrowStats['overdue'] ?? 0} overdue',
            color: CyberpunkTheme.primaryPink,
            icon: Icons.description,
          ),
          _buildStatCard(
            title: 'Pending Requests',
            value: '${borrowStats['pending'] ?? 0}',
            change: '${borrowStats['rejected'] ?? 0} rejected',
            color: CyberpunkTheme.accentOrange,
            icon: Icons.pending_actions,
          ),
          _buildStatCard(
            title: 'Total Activities',
            value: '${activityStats['total'] ?? 0}',
            change:
                'Recent: ${(activityStats['recent'] as List?)?.length ?? 0}',
            color: CyberpunkTheme.primaryPurple,
            icon: Icons.timeline,
          ),
          _buildStatCard(
            title: 'Asset Value',
            value: '\$${(assetStats['totalValue'] ?? 0).toStringAsFixed(0)}',
            change: 'Total system value',
            color: CyberpunkTheme.accentOrange,
            icon: Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.rajdhani(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CyberpunkTheme.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: GoogleFonts.rajdhani(
              fontSize: 10,
              color: CyberpunkTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
