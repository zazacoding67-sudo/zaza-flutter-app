import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED THIS IMPORT
import '../../providers/auth_provider.dart';
import '../../providers/admin_providers.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'system_settings_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const UserManagementScreen(),
    const ReportsScreen(),
    const SystemSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation (Desktop/Tablet)
          if (MediaQuery.of(context).size.width >= 600)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              extended: MediaQuery.of(context).size.width >= 1000,
              backgroundColor: const Color(0xFF004D40),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              selectedLabelTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.6),
              ),
              unselectedLabelTextStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.amber,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ADMIN',
                      style: GoogleFonts.poppins(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assessment),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Menu button for mobile
                      if (MediaQuery.of(context).size.width < 600)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPageTitle(),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Zaza Asset Management System',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // User profile
                      userAsync.when(
                        data: (user) {
                          if (user == null) return const SizedBox();
                          return Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton(
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFF00897B),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Profile',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: Navigate to profile
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await ref
                                          .read(authServiceProvider)
                                          .signOut();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Icon(Icons.error),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation for Mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: const Color(0xFF004D40),
              indicatorColor: Colors.amber,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
                NavigationDestination(
                  icon: Icon(Icons.assessment),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Reports & Analytics';
      case 3:
        return 'System Settings';
      default:
        return 'Admin Panel';
    }
  }
}

// ========== DASHBOARD HOME ==========
class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentActivityProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            statsAsync.when(
              data: (stats) => _buildStatsGrid(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading stats: $error'),
            ),

            const SizedBox(height: 30),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context),

            const SizedBox(height: 30),

            // Recent Activity
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            activityAsync.when(
              data: (activities) => _buildActivityFeed(activities),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading activity: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
            ? 3
            : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              stats['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
              subtitle: '${stats['activeUsers']} active',
            ),
            _buildStatCard(
              'Admin Users',
              stats['adminCount']?.toString() ?? '0',
              Icons.admin_panel_settings,
              Colors.amber,
            ),
            _buildStatCard(
              'Staff Users',
              stats['staffCount']?.toString() ?? '0',
              Icons.badge,
              Colors.green,
            ),
            _buildStatCard(
              'Students',
              stats['studentCount']?.toString() ?? '0',
              Icons.school,
              Colors.purple,
            ),
            _buildStatCard(
              'Active Borrowings',
              stats['activeBorrowings']?.toString() ?? '0',
              Icons.shopping_bag,
              Colors.teal,
            ),
            _buildStatCard(
              'Overdue Items',
              stats['overdueItems']?.toString() ?? '0',
              Icons.warning,
              (stats['overdueItems'] ?? 0) > 0 ? Colors.red : Colors.grey,
            ),
            _buildStatCard(
              'New Users Today',
              stats['newUsersToday']?.toString() ?? '0',
              Icons.person_add,
              Colors.orange,
            ),
            _buildStatCard(
              'Inactive Users',
              stats['inactiveUsers']?.toString() ?? '0',
              Icons.person_off,
              Colors.grey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildQuickActionButton(
          'Add New User',
          Icons.person_add,
          Colors.blue,
          () {
            // TODO: Navigate to add user
          },
        ),
        _buildQuickActionButton(
          'Generate Report',
          Icons.assessment,
          Colors.green,
          () {
            // TODO: Navigate to reports
          },
        ),
        _buildQuickActionButton(
          'View Assets',
          Icons.inventory,
          Colors.orange,
          () {
            // TODO: Navigate to assets
          },
        ),
        _buildQuickActionButton(
          'System Logs',
          Icons.history,
          Colors.purple,
          () {
            // TODO: Navigate to logs
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length > 10 ? 10 : activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final action = activity['action'] ?? '';
    final performedBy = activity['performedByName'] ?? 'Unknown';
    final timestamp = activity['timestamp']; // This might be Timestamp or null

    IconData icon;
    Color color;

    switch (action) {
      case 'user_created':
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case 'user_updated':
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case 'user_deleted':
        icon = Icons.delete;
        color = Colors.red;
        break;
      case 'user_deactivated':
        icon = Icons.person_off;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        _getActivityDescription(activity),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      subtitle: Text(
        'By $performedBy',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: timestamp != null
          ? Text(
              _formatTimestamp(timestamp),
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            )
          : null,
    );
  }

  String _getActivityDescription(Map<String, dynamic> activity) {
    final action = activity['action'] ?? '';
    final details = activity['details'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'user_created':
        return 'New user created: ${details['name'] ?? 'Unknown'}';
      case 'user_updated':
        return 'User profile updated';
      case 'user_deleted':
        return 'User account deleted';
      case 'user_deactivated':
        return 'User account deactivated';
      default:
        return 'System action performed';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime date;

    // Handle both Timestamp and DateTime
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Invalid time';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
