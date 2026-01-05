import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('No user data found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        // Debug: Print user role
        debugPrint('🔍 User role: ${user.role}');

        // Route based on user role
        final role = user.role.toLowerCase().trim();

        switch (role) {
          case 'admin':
            debugPrint('✅ Routing to Admin Dashboard');
            return const AdminDashboardScreen();

          case 'staff':
            debugPrint('✅ Routing to Staff Dashboard');
            return const StaffDashboardScreen();

          case 'student':
            debugPrint('✅ Routing to Student Dashboard');
            return const StudentDashboardScreen();

          default:
            // If role is unknown, treat as student (safest default)
            debugPrint('⚠️ Unknown role: $role - Routing to Student Dashboard');
            return const StudentDashboardScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) {
        // Print error for debugging
        debugPrint('❌ Error loading user: $error');
        debugPrint('Stack trace: $stackTrace');

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  child: const Text('Logout & Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
