// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Create new user (Admin only)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String staffId,
    required String department,
    required String role,
    String? phone,
    required String createdBy,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || name.isEmpty || staffId.isEmpty) {
        return {'success': false, 'message': 'All required fields must be filled'};
      }

      if (password.length < 6) {
        return {'success': false, 'message': 'Password must be at least 6 characters'};
      }

      // Check if email already exists
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        return {'success': false, 'message': 'Email already in use'};
      }

      // Check if staffId already exists
      final existingStaffId = await _firestore
          .collection('users')
          .where('staffId', isEqualTo: staffId)
          .get();
      
      if (existingStaffId.docs.isNotEmpty) {
        return {'success': false, 'message': 'Staff ID already in use'};
      }

      // Create Firebase Auth user
      auth.UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        return {'success': false, 'message': 'Failed to create authentication: ${e.toString()}'};
      }

      final uid = userCredential.user!.uid;

      // Create user document in Firestore
      final user = User(
        id: uid,
        staffId: staffId,
        name: name,
        email: email,
        department: department,
        role: role,
        phone: phone,
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _firestore.collection('users').doc(uid).set(user.toFirestore());

      // Log activity
      await _logActivity(
        action: 'user_created',
        performedBy: createdBy,
        details: {
          'userId': uid,
          'name': name,
          'email': email,
          'role': role,
        },
      );

      return {'success': true, 'message': 'User created successfully', 'userId': uid};
    } catch (e) {
      debugPrint('Error creating user: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String name,
    required String department,
    required String role,
    String? phone,
    required String updatedBy,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'department': department,
        'role': role,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(
        action: 'user_updated',
        performedBy: updatedBy,
        details: {'userId': userId, 'name': name},
      );

      return {'success': true, 'message': 'User updated successfully'};
    } catch (e) {
      debugPrint('Error updating user: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Deactivate user
  Future<Map<String, dynamic>> deactivateUser(String userId, String deactivatedBy) async {
    try {
      // Check if user has active borrowings
      final borrowings = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      
      if (borrowings.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Cannot deactivate: User has ${borrowings.docs.length} active borrowing(s)',
        };
      }

      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(
        action: 'user_deactivated',
        performedBy: deactivatedBy,
        details: {'userId': userId},
      );

      return {'success': true, 'message': 'User deactivated successfully'};
    } catch (e) {
      debugPrint('Error deactivating user: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Activate user
  Future<Map<String, dynamic>> activateUser(String userId, String activatedBy) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(
        action: 'user_activated',
        performedBy: activatedBy,
        details: {'userId': userId},
      );

      return {'success': true, 'message': 'User activated successfully'};
    } catch (e) {
      debugPrint('Error activating user: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete user (soft delete - deactivate only)
  Future<Map<String, dynamic>> deleteUser(String userId, String deletedBy) async {
    try {
      // Check if user has any borrowing history
      final borrowings = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (borrowings.docs.isNotEmpty) {
        // Just deactivate if there's history
        return await deactivateUser(userId, deletedBy);
      }

      // Otherwise, can permanently delete
      await _firestore.collection('users').doc(userId).delete();

      // Try to delete from Firebase Auth (may fail if not current user)
      try {
        // This would need admin SDK in production
        // For now, just mark as deleted in Firestore
      } catch (e) {
        debugPrint('Could not delete from Firebase Auth: $e');
      }

      // Log activity
      await _logActivity(
        action: 'user_deleted',
        performedBy: deletedBy,
        details: {'userId': userId},
      );

      return {'success': true, 'message': 'User deleted successfully'};
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Reset password (send email)
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Generate unique staff ID
  Future<String> generateStaffId(String role) async {
    try {
      final prefix = role.toLowerCase() == 'student' ? 'STU' : 'STF';
      final snapshot = await _firestore
          .collection('users')
          .where('staffId', isGreaterThanOrEqualTo: prefix)
          .where('staffId', isLessThan: '${prefix}Z')
          .orderBy('staffId', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return '$prefix-0001';
      }
      
      final lastId = snapshot.docs.first.data()['staffId'] as String?;
      if (lastId == null || !lastId.startsWith(prefix)) {
        return '$prefix-0001';
      }
      
      final lastNumber = int.tryParse(lastId.split('-').last) ?? 0;
      final newNumber = lastNumber + 1;
      return '$prefix-${newNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Error generating staff ID: $e');
      return 'STF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  // Log activity
  Future<void> _logActivity({
    required String action,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(performedBy).get();
      final performerName = userDoc.exists ? userDoc.data()?['name'] ?? 'Unknown' : 'Unknown';

      await _firestore.collection('activity_logs').add({
        'action': action,
        'performedBy': performedBy,
        'performedByName': performerName,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }
}