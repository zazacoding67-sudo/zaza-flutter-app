import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Create new user (compatible with user_management_screen.dart)
  Future<void> createUser(
    app_user.User user,
    String password,
    String createdBy,
  ) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // Create user document with the auth UID
      final newUser = user.copyWith(
        id: userCredential.user!.uid,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toFirestore());

      // Log activity
      await logActivity(
        action: 'User Created',
        description: 'Created user: ${user.name} (${user.email})',
      );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user (compatible with user_management_screen.dart)
  Future<void> updateUser(app_user.User user, String updatedBy) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());

      // Log activity
      await logActivity(
        action: 'User Updated',
        description: 'Updated user: ${user.name}',
        userId: user.id,
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user (compatible with user_management_screen.dart)
  Future<void> deleteUser(String userId, String deletedBy) async {
    try {
      // Get user data first for logging
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Log activity
      await logActivity(
        action: 'User Deleted',
        description: 'Deleted user: $userName',
      );
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Toggle user active status (compatible with user_management_screen.dart)
  Future<void> toggleUserStatus(
    String userId,
    bool isActive,
    String updatedBy,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });

      // Log activity
      await logActivity(
        action: 'User Status Changed',
        description: 'User ${isActive ? "activated" : "deactivated"}',
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to toggle user status: $e');
    }
  }

  // Get all users
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                app_user.User.fromFirestore(doc.data(), documentId: doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Get user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return app_user.User.fromFirestore(doc.data()!, documentId: doc.id);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Reset user password
  Future<void> resetUserPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Log activity
      await logActivity(
        action: 'Password Reset',
        description: 'Password reset email sent to: $email',
      );
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final borrowingsSnapshot = await _firestore
          .collection('borrowings')
          .get();
      final assetsSnapshot = await _firestore.collection('assets').get();

      final users = usersSnapshot.docs
          .map(
            (doc) =>
                app_user.User.fromFirestore(doc.data(), documentId: doc.id),
          )
          .toList();

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

      int activeBorrowings = 0;
      int overdueItems = 0;
      int pendingRequests = 0;

      for (var doc in borrowingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final dueDate = (data['expectedReturnDate'] as Timestamp?)?.toDate();

        if (status == 'active' || status == 'Borrowed') {
          activeBorrowings++;
          if (dueDate != null && dueDate.isBefore(DateTime.now())) {
            overdueItems++;
          }
        } else if (status == 'pending') {
          pendingRequests++;
        }
      }

      // Count available assets
      int availableAssets = 0;
      for (var doc in assetsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        if (status == 'Available') {
          availableAssets++;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'adminCount': adminCount,
        'staffCount': staffCount,
        'studentCount': studentCount,
        'totalAssets': assetsSnapshot.docs.length,
        'availableAssets': availableAssets,
        'activeBorrowings': activeBorrowings,
        'overdueItems': overdueItems,
        'pendingRequests': pendingRequests,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Log activity
  Future<void> logActivity({
    required String action,
    required String description,
    String? userId,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'description': description,
        'userId': userId ?? _auth.currentUser?.uid,
        'performedBy': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  // Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('Failed to get recent activities: $e');
      return [];
    }
  }

  // Search users
  Future<List<app_user.User>> searchUsers(String query) async {
    try {
      final allUsers = await getAllUsers();
      final lowercaseQuery = query.toLowerCase();

      return allUsers.where((user) {
        return user.name.toLowerCase().contains(lowercaseQuery) ||
            user.email.toLowerCase().contains(lowercaseQuery) ||
            user.staffId.toLowerCase().contains(lowercaseQuery) ||
            user.department.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get users by role
  Future<List<app_user.User>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                app_user.User.fromFirestore(doc.data(), documentId: doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }
}
