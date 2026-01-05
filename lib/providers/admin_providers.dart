import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/user.dart';

// ========== SERVICE PROVIDER ==========

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// ========== USER MANAGEMENT PROVIDERS ==========

/// Stream provider for all users
final allUsersProvider = StreamProvider<List<User>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getAllUsers();
});

/// Stream provider for users by role
final usersByRoleProvider = StreamProvider.family<List<User>, String>((
  ref,
  role,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getUsersByRole(role);
});

/// Future provider for user search
final userSearchProvider = FutureProvider.family<List<User>, String>((
  ref,
  query,
) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.searchUsers(query);
});

/// Future provider for specific user
final userByIdProvider = FutureProvider.family<User?, String>((
  ref,
  userId,
) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getUserById(userId);
});

// ========== STATISTICS PROVIDERS ==========

/// Future provider for dashboard statistics
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getDashboardStats();
});

/// Stream provider for recent activity
final recentActivityProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getRecentActivity(limit: 15);
});

// ========== STATE PROVIDERS FOR UI ==========

/// Selected filter for user list (All, Admin, Staff, Student, Inactive)
final userFilterProvider = StateProvider<String>((ref) => 'All');

/// Search query for users
final userSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected user for detail view/edit
final selectedUserProvider = StateProvider<User?>((ref) => null);
