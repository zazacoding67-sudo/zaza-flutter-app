import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/borrowing.dart';
import '../models/asset.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BorrowingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================== FUTURE-BASED METHODS ==================

  // Get all pending requests as Future
  Future<List<Borrowing>> getPendingRequests() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Borrowing.fromFirestore(doc.data(), documentId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending requests: $e');
      return [];
    }
  }

  // Get active borrowings as Future
  Future<List<Borrowing>> getActiveBorrowings() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'active')
          .orderBy('borrowedDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Borrowing.fromFirestore(doc.data(), documentId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting active borrowings: $e');
      return [];
    }
  }

  // Get user's active borrowings as Future
  Future<List<Borrowing>> getMyActiveBorrowings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) {
        return Borrowing.fromFirestore(doc.data(), documentId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting my active borrowings: $e');
      return [];
    }
  }

  // Get user's pending requests as Future
  Future<List<Borrowing>> getMyPendingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        return Borrowing.fromFirestore(doc.data(), documentId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting my pending requests: $e');
      return [];
    }
  }

  // Approve borrow request
  Future<bool> approveBorrowRequest(String borrowingId) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) return false;

      // Get borrowing record first
      final borrowingDoc = await _firestore
          .collection('borrowings')
          .doc(borrowingId)
          .get();
      if (!borrowingDoc.exists) return false;

      final borrowingData = borrowingDoc.data()!;
      final assetId = borrowingData['assetId'] as String;
      final now = DateTime.now();
      final expectedReturnDate = now.add(const Duration(days: 7));

      // Update borrowing record
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'active',
        'approvedDate': Timestamp.fromDate(now),
        'borrowedDate': Timestamp.fromDate(now),
        'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
        'approvedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status
      await _firestore.collection('assets').doc(assetId).update({
        'status': 'In Use',
        'isAvailable': false,
        'borrowedAt': Timestamp.fromDate(now),
        'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
        'borrowedBy': borrowingData['userId'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(
        action: 'borrow_approved',
        performedBy: adminId,
        details: {'borrowingId': borrowingId, 'assetId': assetId},
      );

      return true;
    } catch (e) {
      debugPrint('Error approving borrow request: $e');
      return false;
    }
  }

  // Reject borrow request
  Future<bool> rejectBorrowRequest(
    String borrowingId,
    String rejectionReason,
  ) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) return false;

      // Get borrowing record
      final borrowingDoc = await _firestore
          .collection('borrowings')
          .doc(borrowingId)
          .get();
      if (!borrowingDoc.exists) return false;

      final borrowingData = borrowingDoc.data()!;

      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedBy': adminId,
        'rejectedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Asset stays Available (no change needed)

      await _logActivity(
        action: 'borrow_rejected',
        performedBy: adminId,
        details: {'borrowingId': borrowingId, 'reason': rejectionReason},
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting borrow request: $e');
      return false;
    }
  }

  // ================== STREAM-BASED METHODS ==================

  // Get all pending requests stream
  Stream<QuerySnapshot> getPendingRequestsStream() {
    return _firestore
        .collection('borrowings')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedDate', descending: true)
        .snapshots();
  }

  // Get active loans stream
  Stream<QuerySnapshot> getActiveLoansStream() {
    return _firestore
        .collection('borrowings')
        .where('status', isEqualTo: 'active')
        .orderBy('borrowedDate', descending: true)
        .snapshots();
  }

  // Get user's pending requests stream
  Stream<QuerySnapshot> getUserPendingRequestsStream(String userId) {
    return _firestore
        .collection('borrowings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get user's active loans stream
  Stream<QuerySnapshot> getUserActiveLoansStream(String userId) {
    return _firestore
        .collection('borrowings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Create a borrowing request
  Future<bool> createBorrowingRequest({
    required String assetId,
    required String assetName,
    required String userId,
    required String userName,
    String purpose = 'General use',
    String notes = '',
  }) async {
    try {
      final now = DateTime.now();

      await _firestore.collection('borrowings').add({
        'assetId': assetId,
        'assetName': assetName,
        'userId': userId,
        'userName': userName,
        'requestedDate': Timestamp.fromDate(now),
        'status': 'pending',
        'purpose': purpose,
        'notes': notes,
        'expectedReturnDate': null,
        'approvedDate': null,
        'borrowedDate': null,
        'actualReturnDate': null,
        'rejectionReason': null,
        'createdAt': Timestamp.fromDate(now),
      });

      // DO NOT update asset status - it stays Available until approved

      await _logActivity(
        action: 'borrow_requested',
        performedBy: userId,
        details: {'assetId': assetId, 'assetName': assetName},
      );

      return true;
    } catch (e) {
      debugPrint('Error creating borrowing request: $e');
      return false;
    }
  }

  // Return an asset
  Future<bool> returnAsset({
    required String borrowingId,
    required String assetId,
    required String returnedBy,
  }) async {
    try {
      final now = DateTime.now();

      // Update borrowing record
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'returned',
        'actualReturnDate': Timestamp.fromDate(now),
        'returnedBy': returnedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status
      await _firestore.collection('assets').doc(assetId).update({
        'status': 'Available',
        'isAvailable': true,
        'borrowedBy': null,
        'borrowedAt': null,
        'expectedReturnDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(
        action: 'asset_returned',
        performedBy: returnedBy,
        details: {'borrowingId': borrowingId, 'assetId': assetId},
      );

      return true;
    } catch (e) {
      debugPrint('Error returning asset: $e');
      return false;
    }
  }

  // Get overdue loans
  Stream<List<Borrowing>> getOverdueLoansStream() {
    return _firestore
        .collection('borrowings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) {
          final overdueList = <Borrowing>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final expectedReturn = data['expectedReturnDate'] as Timestamp?;
            if (expectedReturn != null &&
                DateTime.now().isAfter(expectedReturn.toDate())) {
              overdueList.add(
                Borrowing.fromFirestore(data, documentId: doc.id),
              );
            }
          }
          return overdueList;
        });
  }

  // ================== HELPER METHODS ==================

  // Log activity
  Future<void> _logActivity({
    required String action,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'performedBy': performedBy,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  // Get borrowing statistics for admin dashboard
  Future<Map<String, int>> getBorrowingStats() async {
    try {
      final pendingSnapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'pending')
          .get();

      final activeSnapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'active')
          .get();

      final returnedSnapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'returned')
          .limit(7) // Last 7 days
          .get();

      return {
        'pendingRequests': pendingSnapshot.docs.length,
        'activeLoans': activeSnapshot.docs.length,
        'recentReturns': returnedSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting borrowing stats: $e');
      return {'pendingRequests': 0, 'activeLoans': 0, 'recentReturns': 0};
    }
  }
}
