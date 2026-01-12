// lib/screens/staff/staff_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../services/staff_service.dart';
import '../../services/auth_service.dart';
import 'asset_inventory_screen.dart';
import 'manage_borrowings_screen.dart';
import 'process_returns_screen.dart';
import 'staff_statistics_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final StaffService _staffService = StaffService();
  final AuthService _authService = AuthService();

  Map<String, dynamic> _stats = {};
  List<dynamic> _todayReturns = [];
  List<dynamic> _maintenanceAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _staffService.getStaffStatistics();
      final todayReturns = await _staffService.getTodayScheduledReturns();
      final maintenanceAlerts = await _staffService.getMaintenanceAlerts();

      if (mounted) {
        setState(() {
          _stats = stats;
          _todayReturns = todayReturns;
          _maintenanceAlerts = maintenanceAlerts;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.deepBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: CyberpunkTheme.primaryPink.withAlpha(100)),
        ),
        title: Text(
          'LOGOUT CONFIRMATION',
          style: CyberpunkTheme.heading3.copyWith(
            color: CyberpunkTheme.primaryPink,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: CyberpunkTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: CyberpunkTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'LOGOUT',
              style: TextStyle(
                color: CyberpunkTheme.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoading)
            Expanded(child: _buildLoading())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: CyberpunkTheme.primaryPink,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildQuickStats(),
                      _buildQuickActions(),
                      _buildAlerts(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CyberpunkTheme.cardDark, CyberpunkTheme.deepBlack],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: CyberpunkTheme.primaryCyan.withAlpha(77),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize,
            color: CyberpunkTheme.primaryCyan,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'STAFF OPERATIONS',
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: CyberpunkTheme.neonGreen),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: CyberpunkTheme.primaryPink),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: CyberpunkTheme.primaryCyan),
          const SizedBox(height: 20),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.rajdhani(
              color: CyberpunkTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK STATS',
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
                child: _buildStatCard(
                  'Pending',
                  _stats['pendingRequests']?.toString() ?? '0',
                  Icons.pending_actions,
                  CyberpunkTheme.primaryPink,
                  urgent: (_stats['pendingRequests'] ?? 0) > 5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  _stats['activeBorrowings']?.toString() ?? '0',
                  Icons.sync,
                  CyberpunkTheme.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Overdue',
                  _stats['overdueItems']?.toString() ?? '0',
                  Icons.warning,
                  CyberpunkTheme.warningYellow,
                  urgent: (_stats['overdueItems'] ?? 0) > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Due Today',
                  _stats['todayReturns']?.toString() ?? '0',
                  Icons.today,
                  CyberpunkTheme.neonGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool urgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent ? color : color.withAlpha(77),
          width: urgent ? 2 : 1,
        ),
        boxShadow: urgent
            ? [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (urgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '!',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.primaryCyan,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Manage Borrowings',
            'Approve or reject pending requests',
            Icons.approval,
            CyberpunkTheme.primaryPink,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageBorrowingsScreen(),
                ),
              );
            },
            badge: _stats['pendingRequests'] ?? 0,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'Process Returns',
            'Check-in returned items and inspect condition',
            Icons.assignment_return,
            CyberpunkTheme.primaryCyan,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProcessReturnsScreen(),
                ),
              );
            },
            badge: _stats['todayReturns'] ?? 0,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'Asset Inventory',
            'View and manage asset conditions',
            Icons.inventory_2,
            CyberpunkTheme.neonGreen,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssetInventoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'View Statistics',
            'Operational metrics and insights',
            Icons.bar_chart,
            CyberpunkTheme.warningYellow,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StaffStatisticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int badge = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CyberpunkTheme.textPrimary,
                        ),
                      ),
                      if (badge > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge.toString(),
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CyberpunkTheme.deepBlack,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      color: CyberpunkTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    final hasOverdue = (_stats['overdueItems'] ?? 0) > 0;
    final hasMaintenance = _maintenanceAlerts.isNotEmpty;

    if (!hasOverdue && !hasMaintenance) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALERTS & NOTIFICATIONS',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CyberpunkTheme.warningYellow,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (hasOverdue)
            _buildAlertCard(
              'Overdue Items',
              '${_stats['overdueItems']} items are overdue for return',
              Icons.warning_amber,
              CyberpunkTheme.warningYellow,
            ),
          if (hasMaintenance) ...[
            if (hasOverdue) const SizedBox(height: 10),
            _buildAlertCard(
              'Maintenance Required',
              '${_maintenanceAlerts.length} items need attention',
              Icons.build,
              CyberpunkTheme.primaryPink,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
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
  }
}
