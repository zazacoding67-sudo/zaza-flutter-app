import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/cyberpunk_theme.dart';
import 'admin/admin_dashboard_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: CyberpunkTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 60,
                    color: CyberpunkTheme.statusBorrowed,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No user data',
                    style: TextStyle(color: CyberpunkTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkTheme.primaryPink,
                    ),
                    onPressed: () async =>
                        await ref.read(authServiceProvider).signOut(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        switch (user.role.toLowerCase()) {
          case 'admin':
            return const AdminDashboardScreen();
          case 'staff':
            return const StaffDashboardScreen();
          default:
            return const StudentDashboardScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: CyberpunkTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: CyberpunkTheme.primaryPink),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CyberpunkTheme.background,
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: CyberpunkTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}
