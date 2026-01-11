// lib/services/borrowing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/borrowing.dart';
import '../models/asset.dart';
import '../models/user.dart';

class BorrowingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create borrowing request
  Future<String?> createBorrowingRequest({
    required String assetId,
    required String userId,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      // Get asset and user details
      final assetDoc = await _firestore.collection('assets').doc(assetId).get();
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!assetDoc.exists || !userDoc.exists) {
        debugPrint('Asset or user not found');
        return null;
      }
      
      final asset = Asset.fromFirestore(assetDoc.data()!, documentId: assetDoc.id);
      final user = User.fromFirestore(userDoc.data()!, documentId: userDoc.id);
      
      // Check if asset is available
      if (asset.status != 'available') {
        debugPrint('Asset not available');
        return null;
      }
      
      // Create borrowing record
      final borrowing = Borrowing(
        id: '',
        assetId: assetId,
        assetName: asset.name,
        userId: userId,
        userName: user.name,
        userEmail: user.email,
        borrowDate: DateTime.now(),
        dueDate: dueDate,
        status: 'pending',
        notes: notes,
        approvedBy: userId, // Will be updated when approved
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final docRef = await _firestore.collection('borrowings').add(borrowing.toFirestore());
      
      // Log activity
      await _logActivity(
        action: 'borrowing_requested',
        performedBy: userId,
        details: {'borrowingId': docRef.id, 'assetName': asset.name},
      );
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating borrowing request: $e');
      return null;
    }
  }

  // Approve borrowing (Staff/Admin only)
  Future<bool> approveBorrowing(String borrowingId, String approvedById) async {
    try {
      final borrowingDoc = await _firestore.collection('borrowings').doc(borrowingId).get();
      if (!borrowingDoc.exists) return false;
      
      final borrowing = Borrowing.fromFirestore(borrowingDoc.data()!, documentId: borrowingDoc.id);
      
      // Update borrowing status
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'active',
        'approvedBy': approvedById,
        'borrowDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update asset status
      await _firestore.collection('assets').doc(borrowing.assetId).update({
        'status': 'borrowed',
        'assignedTo': borrowing.userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log activity
      await _logActivity(
        action: 'borrowing_approved',
        performedBy: approvedById,
        details: {'borrowingId': borrowingId, 'assetName': borrowing.assetName},
      );
      
      return true;
    } catch (e) {
      debugPrint('Error approving borrowing: $e');
      return false;
    }
  }

  // Reject borrowing
  Future<bool> rejectBorrowing(String borrowingId, String rejectedById) async {
    try {
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log activity
      await _logActivity(
        action: 'borrowing_rejected',
        performedBy: rejectedById,
        details: {'borrowingId': borrowingId},
      );
      
      return true;
    } catch (e) {
      debugPrint('Error rejecting borrowing: $e');
      return false;
    }
  }

  // Return asset
  Future<bool> returnAsset({
    required String borrowingId,
    required String returnedToId,
    String? returnNotes,
  }) async {
    try {
      final borrowingDoc = await _firestore.collection('borrowings').doc(borrowingId).get();
      if (!borrowingDoc.exists) return false;
      
      final borrowing = Borrowing.fromFirestore(borrowingDoc.data()!, documentId: borrowingDoc.id);
      
      // Update borrowing status
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'returned',
        'returnDate': FieldValue.serverTimestamp(),
        'returnedTo': returnedToId,
        'returnNotes': returnNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update asset status
      await _firestore.collection('assets').doc(borrowing.assetId).update({
        'status': 'available',
        'assignedTo': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log activity
      await _logActivity(
        action: 'asset_returned',
        performedBy: returnedToId,
        details: {
          'borrowingId': borrowingId,
          'assetName': borrowing.assetName,
          'userId': borrowing.userId,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error returning asset: $e');
      return false;
    }
  }

  // Get user's borrowings stream
  Stream<List<Borrowing>> getUserBorrowingsStream(String userId) {
    return _firestore
        .collection('borrowings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
            .toList());
  }

  // Get all borrowings stream
  Stream<List<Borrowing>> getAllBorrowingsStream() {
    return _firestore
        .collection('borrowings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
            .toList());
  }

  // Get active borrowings stream
  Stream<List<Borrowing>> getActiveBorrowingsStream() {
    return _firestore
        .collection('borrowings')
        .where('status', isEqualTo: 'active')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
            .toList());
  }

  // Get pending borrowings stream
  Stream<List<Borrowing>> getPendingBorrowingsStream() {
    return _firestore
        .collection('borrowings')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
            .toList());
  }

  // Update overdue status (run periodically)
  Future<void> updateOverdueStatus() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'active')
          .get();
      
      for (var doc in snapshot.docs) {
        final borrowing = Borrowing.fromFirestore(doc.data(), documentId: doc.id);
        if (borrowing.dueDate.isBefore(now)) {
          await _firestore.collection('borrowings').doc(doc.id).update({
            'status': 'overdue',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating overdue status: $e');
    }
  }

  // Log activity
  Future<void> _logActivity({
    required String action,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Get performer name
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