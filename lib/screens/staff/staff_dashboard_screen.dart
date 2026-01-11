import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as app_user;
import '../../theme/cyberpunk_theme.dart';
import '../assets_screen.dart';
import '../borrowings_screen.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _StaffHome(),
    const AssetsScreen(),
    const BorrowingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.purpleCyanGradient,
          ),
        ),
        title: Text(
          'STAFF PORTAL',
          style: CyberpunkTheme.heading3.copyWith(
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CyberpunkTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: CyberpunkTheme.primaryPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: CyberpunkTheme.primaryPurple.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: CyberpunkTheme.textSecondary,
              ),
              selectedIcon: Icon(Icons.home, color: CyberpunkTheme.primaryCyan),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.inventory_outlined,
                color: CyberpunkTheme.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.inventory,
                color: CyberpunkTheme.primaryCyan,
              ),
              label: 'Assets',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.assignment_outlined,
                color: CyberpunkTheme.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.assignment,
                color: CyberpunkTheme.primaryCyan,
              ),
              label: 'Borrowings',
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffHome extends ConsumerWidget {
  const _StaffHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('No user data'));
        }

        return _buildHomeContent(user, context);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.primaryCyan),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 60, color: CyberpunkTheme.primaryPink),
            const SizedBox(height: 16),
            Text('Error: $error', style: CyberpunkTheme.bodyText),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(app_user.User user, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: CyberpunkTheme.purpleCyanGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CyberpunkTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                      style: CyberpunkTheme.heading1.copyWith(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK',
                        style: CyberpunkTheme.bodyText.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name.toUpperCase(),
                        style: CyberpunkTheme.heading2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${user.role.toUpperCase()} • ${user.department.toUpperCase()}',
                          style: CyberpunkTheme.bodyText.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions
          Text(
            'QUICK ACTIONS',
            style: CyberpunkTheme.heading2.copyWith(
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                context,
                'VIEW\nASSETS',
                Icons.inventory_2,
                CyberpunkTheme.primaryCyan,
                () {
                  final state = context
                      .findAncestorStateOfType<_StaffDashboardScreenState>();
                  state?.setState(() => state._selectedIndex = 1);
                },
              ),
              _buildActionCard(
                context,
                'MANAGE\nBORROWINGS',
                Icons.assignment_turned_in,
                CyberpunkTheme.neonGreen,
                () {
                  final state = context
                      .findAncestorStateOfType<_StaffDashboardScreenState>();
                  state?.setState(() => state._selectedIndex = 2);
                },
              ),
              _buildActionCard(
                context,
                'PROCESS\nRETURNS',
                Icons.check_circle,
                CyberpunkTheme.primaryPink,
                () {
                  final state = context
                      .findAncestorStateOfType<_StaffDashboardScreenState>();
                  state?.setState(() => state._selectedIndex = 2);
                },
              ),
              _buildActionCard(
                context,
                'VIEW\nSTATISTICS',
                Icons.bar_chart,
                CyberpunkTheme.primaryPurple,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'COMING SOON',
                        style: CyberpunkTheme.buttonText,
                      ),
                      backgroundColor: CyberpunkTheme.surfaceDark,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Info Section
          Text(
            'YOUR INFORMATION',
            style: CyberpunkTheme.heading2.copyWith(
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

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
            child: Column(
              children: [
                _buildInfoRow(Icons.badge, 'STAFF ID', user.staffId),
                const Divider(height: 24, color: Colors.white12),
                _buildInfoRow(Icons.email, 'EMAIL', user.email),
                const Divider(height: 24, color: Colors.white12),
                _buildInfoRow(Icons.business, 'DEPARTMENT', user.department),
                if (user.phone != null) ...[
                  const Divider(height: 24, color: Colors.white12),
                  _buildInfoRow(Icons.phone, 'PHONE', user.phone!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: CyberpunkTheme.heading3.copyWith(
                fontSize: 12,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CyberpunkTheme.primaryCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: CyberpunkTheme.primaryCyan, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CyberpunkTheme.bodyText.copyWith(
                  fontSize: 10,
                  color: CyberpunkTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: CyberpunkTheme.heading3.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
