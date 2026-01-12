// lib/screens/admin/admin_dashboard_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/cyberpunk_theme.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';
import 'user_management_screen.dart';
import 'reports/reports_screen.dart';
import 'system_settings_screen.dart';
import 'add_asset_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalAssets = 0;
  int _activeLoans = 0;
  int _availableAssets = 0; // NEW: Show available instead of pending
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final adminService = ref.read(adminServiceProvider);

      // Load dashboard statistics
      final stats = await adminService.getDashboardStats();

      // Load recent activity
      final activity = await adminService.getRecentActivity(limit: 10);

      setState(() {
        _totalUsers = stats['totalUsers'] ?? 0;
        _totalAssets = stats['totalAssets'] ?? 0;
        _activeLoans = stats['activeBorrowings'] ?? 0;
        _availableAssets =
            stats['availableAssets'] ?? 0; // Changed from pending
        _recentActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: CyberpunkTheme.primaryPink,
          ),
        );
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
          'Are you sure you want to logout of the admin dashboard?',
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
      await ref.read(authServiceProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkCyanGradient,
          ),
        ),
        title: Text(
          'ADMIN DASHBOARD',
          style: CyberpunkTheme.heading3.copyWith(
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboardContent()
          : _selectedIndex == 1
          ? const UserManagementScreen()
          : _selectedIndex == 2
          ? const ReportsScreen()
          : const SystemSettingsScreen(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          Future.delayed(const Duration(milliseconds: 500)),
          Future(() => _loadDashboardData()),
        ]);
      },
      color: CyberpunkTheme.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 30),
            _buildQuickActions(),
            const SizedBox(height: 30),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.people,
          value: _totalUsers.toString(),
          label: 'TOTAL USERS',
          subtitle: 'All system users',
          color: CyberpunkTheme.primaryCyan,
        ),
        _buildStatCard(
          icon: Icons.inventory,
          value: _totalAssets.toString(),
          label: 'TOTAL ASSETS',
          subtitle: '$_availableAssets available',
          color: CyberpunkTheme.neonGreen,
        ),
        _buildStatCard(
          icon: Icons.description,
          value: _activeLoans.toString(),
          label: 'ACTIVE LOANS',
          subtitle: 'Currently borrowed',
          color: CyberpunkTheme.primaryPink,
        ),
        // REMOVED: Pending Requests Card
        // Changed to show Available Assets
        _buildStatCard(
          icon: Icons.check_circle,
          value: _availableAssets.toString(),
          label: 'AVAILABLE',
          subtitle: 'Ready to borrow',
          color: CyberpunkTheme.primaryPurple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: CyberpunkTheme.heading1.copyWith(
                  fontSize: 36,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CyberpunkTheme.heading3.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: CyberpunkTheme.bodyText.copyWith(
                  fontSize: 10,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: CyberpunkTheme.heading2.copyWith(
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildActionButton(
              icon: Icons.person_add,
              label: 'ADD USER',
              color: CyberpunkTheme.primaryCyan,
              onTap: () => _navigateToAddUser(),
            ),
            _buildActionButton(
              icon: Icons.add_box,
              label: 'ADD ASSET',
              color: CyberpunkTheme.neonGreen,
              onTap: () => _navigateToAddAsset(),
            ),
            _buildActionButton(
              icon: Icons.assessment,
              label: 'REPORTS',
              color: CyberpunkTheme.primaryPink,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _buildActionButton(
              icon: Icons.settings,
              label: 'SETTINGS',
              color: CyberpunkTheme.primaryPurple,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: CyberpunkTheme.buttonText.copyWith(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: CyberpunkTheme.heading2.copyWith(
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CyberpunkTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CyberpunkTheme.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: _recentActivity.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No recent activity',
                      style: CyberpunkTheme.bodyText.copyWith(
                        color: CyberpunkTheme.textMuted,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white12, height: 20),
                  itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    return _buildActivityItem(activity);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    final action = activity['action']?.toString().toLowerCase() ?? '';

    if (action.contains('user') && action.contains('create')) {
      icon = Icons.person_add;
      color = CyberpunkTheme.primaryCyan;
    } else if (action.contains('borrow')) {
      icon = action.contains('return')
          ? Icons.assignment_return
          : Icons.request_page;
      color = action.contains('return')
          ? CyberpunkTheme.neonGreen
          : CyberpunkTheme.accentOrange;
    } else if (action.contains('asset')) {
      icon = Icons.add_box;
      color = CyberpunkTheme.neonGreen;
    } else if (action.contains('update')) {
      icon = Icons.edit;
      color = CyberpunkTheme.primaryPurple;
    } else {
      icon = Icons.circle_notifications;
      color = CyberpunkTheme.textSecondary;
    }

    final timestamp = activity['timestamp'];
    String timeString = '';
    if (timestamp != null) {
      try {
        final date = timestamp is DateTime
            ? timestamp
            : (timestamp as Timestamp).toDate();
        final diff = DateTime.now().difference(date);
        if (diff.inMinutes < 60) {
          timeString = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeString = '${diff.inHours}h ago';
        } else {
          timeString = '${diff.inDays}d ago';
        }
      } catch (e) {
        timeString = '';
      }
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['action'] ?? 'Activity',
                style: CyberpunkTheme.heading3.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                activity['description'] ?? '',
                style: CyberpunkTheme.bodyText.copyWith(
                  fontSize: 11,
                  color: CyberpunkTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (timeString.isNotEmpty)
          Text(
            timeString,
            style: CyberpunkTheme.bodyText.copyWith(
              fontSize: 10,
              color: CyberpunkTheme.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: CyberpunkTheme.primaryPink.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        indicatorColor: CyberpunkTheme.primaryPink.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: CyberpunkTheme.textSecondary,
            ),
            selectedIcon: Icon(Icons.home, color: CyberpunkTheme.primaryPink),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outlined,
              color: CyberpunkTheme.textSecondary,
            ),
            selectedIcon: Icon(Icons.people, color: CyberpunkTheme.primaryPink),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.analytics_outlined,
              color: CyberpunkTheme.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.analytics,
              color: CyberpunkTheme.primaryPink,
            ),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: CyberpunkTheme.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.settings,
              color: CyberpunkTheme.primaryPink,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    setState(() => _selectedIndex = 1);
  }

  void _navigateToAddAsset() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAssetScreen()),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
      }
    });
  }
}
