import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart' as app_user;
import '../theme/cyberpunk_theme.dart';
import 'assets_screen.dart';
import 'my_borrowed_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _StudentHome(),
    const AssetsScreen(),
    const MyBorrowedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CyberpunkTheme.pinkPurpleGradient,
          ),
        ),
        title: Text(
          'STUDENT PORTAL',
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
              color: CyberpunkTheme.primaryPink.withOpacity(0.2),
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
              icon: Icon(Icons.search, color: CyberpunkTheme.textSecondary),
              selectedIcon: Icon(
                Icons.search,
                color: CyberpunkTheme.primaryPink,
              ),
              label: 'Browse',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.shopping_bag_outlined,
                color: CyberpunkTheme.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.shopping_bag,
                color: CyberpunkTheme.primaryPink,
              ),
              label: 'My Items',
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentHome extends ConsumerWidget {
  const _StudentHome();

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
      error: (error, stackTrace) {
        return Center(
          child: Text('Error: $error', style: CyberpunkTheme.bodyText),
        );
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
        );
      },
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
              gradient: CyberpunkTheme.pinkPurpleGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'S',
                          style: CyberpunkTheme.heading1.copyWith(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            style: CyberpunkTheme.heading2.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STUDENT ID',
                            style: CyberpunkTheme.bodyText.copyWith(
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            user.staffId,
                            style: CyberpunkTheme.heading3.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick Access
          Text(
            'QUICK ACCESS',
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
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                context,
                'BROWSE\nASSETS',
                Icons.search,
                CyberpunkTheme.primaryCyan,
                () {
                  final state = context
                      .findAncestorStateOfType<_StudentDashboardScreenState>();
                  state?.setState(() => state._selectedIndex = 1);
                },
              ),
              _buildActionCard(
                context,
                'MY\nITEMS',
                Icons.shopping_bag,
                CyberpunkTheme.primaryPink,
                () {
                  final state = context
                      .findAncestorStateOfType<_StudentDashboardScreenState>();
                  state?.setState(() => state._selectedIndex = 2);
                },
              ),
              _buildActionCard(
                context,
                'HISTORY',
                Icons.history,
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
              _buildActionCard(
                context,
                'HELP',
                Icons.help_outline,
                CyberpunkTheme.neonGreen,
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

          // Stats
          Text(
            'YOUR STATS',
            style: CyberpunkTheme.heading2.copyWith(
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '5',
                  'ITEMS BORROWED',
                  CyberpunkTheme.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '2',
                  'CURRENTLY ACTIVE',
                  CyberpunkTheme.primaryCyan,
                ),
              ),
            ],
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

  Widget _buildStatCard(String value, String label, Color color) {
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
        children: [
          Text(
            value,
            style: CyberpunkTheme.heading1.copyWith(fontSize: 36, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: CyberpunkTheme.bodyText.copyWith(
              fontSize: 10,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
