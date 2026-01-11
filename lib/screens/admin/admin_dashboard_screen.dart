import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/glass_theme.dart';
import '../../providers/admin_providers.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'system_settings_screen.dart';
import '../assets_screen.dart';

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
  int _pendingRequests = 0;
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
        _activeLoans = stats['activeLoans'] ?? 0;
        _pendingRequests = stats['pendingRequests'] ?? 0;
        _recentActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GlassTheme.primaryColor,
              GlassTheme.secondaryColor,
              GlassTheme.accentColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _selectedIndex == 0
              ? _buildDashboardContent()
              : _selectedIndex == 1
              ? const UserManagementScreen()
              : _selectedIndex == 2
              ? const ReportsScreen()
              : const SystemSettingsScreen(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: GlassTheme.accentColor),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          Future.delayed(const Duration(milliseconds: 500)),
          Future(() => _loadDashboardData()),
        ]);
      },
      color: GlassTheme.accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildStatsGrid(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassTheme.glassDecoration(),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: GlassTheme.accentColor,
            size: 32,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'System Overview',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
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
          subtitle: '+${(_totalUsers * 0.15).toInt()} this month',
          color: GlassTheme.accentColor,
        ),
        _buildStatCard(
          icon: Icons.inventory,
          value: _totalAssets.toString(),
          label: 'TOTAL ASSETS',
          subtitle: '$_totalAssets available',
          color: const Color(0xFF00FF00),
        ),
        _buildStatCard(
          icon: Icons.description,
          value: _activeLoans.toString(),
          label: 'ACTIVE LOANS',
          subtitle: '${(_activeLoans * 0.056).toInt()} overdue',
          color: const Color(0xFFFF0080),
        ),
        _buildStatCard(
          icon: Icons.pending_actions,
          value: _pendingRequests.toString(),
          label: 'PENDING',
          subtitle: 'Action needed',
          color: const Color(0xFF8000FF),
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
      decoration: GlassTheme.glassDecoration(),
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
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
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
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
              color: GlassTheme.accentColor,
              onTap: () => _navigateToAddUser(),
            ),
            _buildActionButton(
              icon: Icons.add_box,
              label: 'ADD ASSET',
              color: const Color(0xFF00FF00),
              onTap: () => _navigateToAddAsset(),
            ),
            _buildActionButton(
              icon: Icons.assessment,
              label: 'REPORTS',
              color: const Color(0xFFFF0080),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _buildActionButton(
              icon: Icons.settings,
              label: 'SETTINGS',
              color: const Color(0xFF8000FF),
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
        decoration: GlassTheme.glassDecoration().copyWith(
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
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
        const Text(
          'RECENT ACTIVITY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: GlassTheme.glassDecoration(),
          child: _recentActivity.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.white.withOpacity(0.1), height: 20),
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

    switch (activity['type']) {
      case 'user_registered':
        icon = Icons.person_add;
        color = GlassTheme.accentColor;
        break;
      case 'borrowing_requested':
        icon = Icons.request_page;
        color = Colors.orange;
        break;
      case 'borrowing_approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'borrowing_returned':
        icon = Icons.assignment_return;
        color = Colors.blue;
        break;
      case 'asset_added':
        icon = Icons.add_box;
        color = const Color(0xFF00FF00);
        break;
      default:
        icon = Icons.circle_notifications;
        color = Colors.white;
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
                activity['title'] ?? 'Activity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity['description'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          activity['time'] ?? '',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: GlassTheme.glassDecoration(),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: GlassTheme.accentColor,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToAddAsset() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AssetsScreen()),
    ).then((_) => _loadDashboardData());
  }
}
