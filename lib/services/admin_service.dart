import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // ========== USER MANAGEMENT ==========

  /// Get all users (admin only)
  Stream<List<User>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), documentId: doc.id))
              .toList();
        });
  }

  /// Get users by role
  Stream<List<User>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), documentId: doc.id))
              .toList();
        });
  }

  /// Get active users count
  Future<int> getActiveUsersCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!, documentId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Create new user (admin only)
  /// Returns the created User object or null if failed
  Future<User?> createUser({
    required String email,
    required String password,
    required String name,
    required String staffId,
    required String department,
    required String role,
    String? phone,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated admin user');
      }

      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserId = userCredential.user!.uid;

      // Create user document in Firestore
      final newUser = User(
        id: newUserId,
        staffId: staffId,
        name: name,
        email: email,
        department: department,
        role: role,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: currentUser.uid,
      );

      await _firestore
          .collection('users')
          .doc(newUserId)
          .set(newUser.toFirestore());

      // Log audit trail
      await _logAuditAction(
        action: 'user_created',
        targetId: newUserId,
        targetType: 'user',
        details: {'name': name, 'email': email, 'role': role},
      );

      return newUser;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  /// Update user details
  Future<bool> updateUser({
    required String userId,
    String? name,
    String? staffId,
    String? department,
    String? role,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (staffId != null) updateData['staffId'] = staffId;
      if (department != null) updateData['department'] = department;
      if (role != null) updateData['role'] = role;
      if (phone != null) updateData['phone'] = phone;
      if (isActive != null) updateData['isActive'] = isActive;

      if (updateData.isEmpty) return false;

      await _firestore.collection('users').doc(userId).update(updateData);

      // Log audit trail
      await _logAuditAction(
        action: 'user_updated',
        targetId: userId,
        targetType: 'user',
        details: updateData,
      );

      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Deactivate user (soft delete)
  Future<bool> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });

      await _logAuditAction(
        action: 'user_deactivated',
        targetId: userId,
        targetType: 'user',
        details: {'isActive': false},
      );

      return true;
    } catch (e) {
      print('Error deactivating user: $e');
      return false;
    }
  }

  /// Reactivate user
  Future<bool> reactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
      });

      await _logAuditAction(
        action: 'user_reactivated',
        targetId: userId,
        targetType: 'user',
        details: {'isActive': true},
      );

      return true;
    } catch (e) {
      print('Error reactivating user: $e');
      return false;
    }
  }

  /// Delete user permanently (admin only - use with caution)
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      await _logAuditAction(
        action: 'user_deleted',
        targetId: userId,
        targetType: 'user',
        details: {'permanently_deleted': true},
      );

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // ========== STATISTICS ==========

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Total users
      final totalUsersSnapshot = await _firestore
          .collection('users')
          .count()
          .get();
      final totalUsers = totalUsersSnapshot.count ?? 0;

      // Active users
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      final activeUsers = activeUsersSnapshot.count ?? 0;

      // Users by role
      final adminCount = await _getUserCountByRole('admin');
      final staffCount = await _getUserCountByRole('staff');
      final studentCount = await _getUserCountByRole('student');

      // Active borrowings
      final activeBorrowingsSnapshot = await _firestore
          .collection('borrow_records')
          .where('status', isEqualTo: 'Borrowed')
          .count()
          .get();
      final activeBorrowings = activeBorrowingsSnapshot.count ?? 0;

      // Overdue items
      final overdueSnapshot = await _firestore
          .collection('borrow_records')
          .where('status', isEqualTo: 'Borrowed')
          .where('expectedReturnDate', isLessThan: Timestamp.now())
          .count()
          .get();
      final overdueCount = overdueSnapshot.count ?? 0;

      // Today's new users
      final todayUsersSnapshot = await _firestore
          .collection('users')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .count()
          .get();
      final newUsersToday = todayUsersSnapshot.count ?? 0;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'inactiveUsers': totalUsers - activeUsers,
        'adminCount': adminCount,
        'staffCount': staffCount,
        'studentCount': studentCount,
        'activeBorrowings': activeBorrowings,
        'overdueItems': overdueCount,
        'newUsersToday': newUsersToday,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {};
    }
  }

  Future<int> _getUserCountByRole(String role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ========== RECENT ACTIVITY ==========

  /// Get recent activity feed
  Stream<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // ========== AUDIT LOGGING ==========

  /// Log admin action for audit trail
  Future<void> _logAuditAction({
    required String action,
    required String targetId,
    required String targetType,
    required Map<String, dynamic> details,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      await _firestore.collection('audit_logs').add({
        'action': action,
        'performedBy': currentUser.uid,
        'performedByName': userName,
        'targetId': targetId,
        'targetType': targetType,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
      });
    } catch (e) {
      print('Error logging audit action: $e');
    }
  }

  // ========== SEARCH USERS ==========

  /// Search users by name or email
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Get all users and filter locally (Firestore doesn't support full-text search)
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data(), documentId: doc.id))
          .where(
            (user) =>
                user.name.toLowerCase().contains(queryLower) ||
                user.email.toLowerCase().contains(queryLower) ||
                user.staffId.toLowerCase().contains(queryLower),
          )
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
