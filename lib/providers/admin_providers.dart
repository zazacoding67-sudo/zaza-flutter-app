import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

// ========== DASHBOARD STATS ==========
final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Get all users
      final usersSnapshot = await firestore.collection('users').get();
      final users = usersSnapshot.docs
          .map(
            (doc) =>
                app_user.User.fromFirestore(doc.data(), documentId: doc.id),
          )
          .toList();

      // Get borrowings
      final borrowingsSnapshot = await firestore.collection('borrowings').get();

      // Calculate stats
      final totalUsers = users.length;
      final activeUsers = users.where((u) => u.isActive).length;
      final adminCount = users
          .where((u) => u.role.toLowerCase() == 'admin')
          .length;
      final staffCount = users
          .where((u) => u.role.toLowerCase() == 'staff')
          .length;
      final studentCount = users
          .where((u) => u.role.toLowerCase() == 'student')
          .length;
      final inactiveUsers = users.where((u) => !u.isActive).length;

      // Get today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final newUsersToday = users.where((u) {
        if (u.createdAt == null) return false;
        final createdDate = DateTime(
          u.createdAt!.year,
          u.createdAt!.month,
          u.createdAt!.day,
        );
        return createdDate == today;
      }).length;

      // Count active and overdue borrowings
      int activeBorrowings = 0;
      int overdueItems = 0;

      for (var doc in borrowingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final dueDate = (data['expectedReturnDate'] as Timestamp?)?.toDate();

        if (status == 'active' || status == 'Borrowed') {
          activeBorrowings++;
          if (dueDate != null && dueDate.isBefore(DateTime.now())) {
            overdueItems++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'adminCount': adminCount,
        'staffCount': staffCount,
        'studentCount': studentCount,
        'activeBorrowings': activeBorrowings,
        'overdueItems': overdueItems,
        'newUsersToday': newUsersToday,
        'inactiveUsers': inactiveUsers,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'adminCount': 0,
        'staffCount': 0,
        'studentCount': 0,
        'activeBorrowings': 0,
        'overdueItems': 0,
        'newUsersToday': 0,
        'inactiveUsers': 0,
      };
    }
  },
);

// ========== RECENT ACTIVITY ==========
final recentActivityProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final firestore = FirebaseFirestore.instance;

      try {
        final activitySnapshot = await firestore
            .collection('activity_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        return activitySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
      } catch (e) {
        print('Error fetching recent activity: $e');
        return [];
      }
    });

// ========== ALL USERS ==========
final allUsersProvider = StreamProvider.autoDispose<List<app_user.User>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) =>
                  app_user.User.fromFirestore(doc.data(), documentId: doc.id),
            )
            .toList(),
      );
});

// ========== SEARCH ==========
final userSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredUsersProvider =
    Provider.autoDispose<AsyncValue<List<app_user.User>>>((ref) {
      final usersAsync = ref.watch(allUsersProvider);
      final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();

      return usersAsync.whenData((users) {
        if (searchQuery.isEmpty) return users;
        return users
            .where(
              (user) =>
                  user.name.toLowerCase().contains(searchQuery) ||
                  user.email.toLowerCase().contains(searchQuery) ||
                  user.staffId.toLowerCase().contains(searchQuery) ||
                  user.department.toLowerCase().contains(searchQuery),
            )
            .toList();
      });
    });
