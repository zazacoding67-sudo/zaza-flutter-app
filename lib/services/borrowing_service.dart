// Save this as: lib/services/borrowing_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/borrowing.dart';

class BorrowingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== CREATE BORROW REQUEST ====================

  // User requests to borrow an asset
  Future<String> createBorrowRequest({
    required String assetId,
    required String assetName,
    required DateTime expectedReturnDate,
    required String purpose,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get user details
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();

      if (userData == null) {
        throw Exception('User data not found');
      }

      // Check if asset is available
      final assetDoc = await _firestore.collection('assets').doc(assetId).get();
      final assetData = assetDoc.data();

      if (assetData == null) {
        throw Exception('Asset not found');
      }

      if (assetData['status'] != 'Available') {
        throw Exception('Asset is not available for borrowing');
      }

      // Create borrowing request
      final borrowingData = {
        'assetId': assetId,
        'assetName': assetName,
        'userId': currentUser.uid,
        'userName': userData['name'] ?? 'Unknown',
        'userEmail': userData['email'] ?? currentUser.email,
        'requestedDate': FieldValue.serverTimestamp(),
        'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
        'status': 'pending', // Waiting for admin approval
        'purpose': purpose,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('borrowings')
          .add(borrowingData);

      // Log activity
      await _logActivity(
        action: 'Borrow Request Created',
        description: 'Requested to borrow: $assetName',
        userId: currentUser.uid,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create borrow request: $e');
    }
  }

  // ==================== ADMIN ACTIONS ====================

  // Admin approves a borrow request
  Future<void> approveBorrowRequest(String borrowingId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get borrowing details
      final borrowingDoc = await _firestore
          .collection('borrowings')
          .doc(borrowingId)
          .get();
      final borrowingData = borrowingDoc.data();

      if (borrowingData == null) {
        throw Exception('Borrowing request not found');
      }

      final assetId = borrowingData['assetId'];

      // Start a batch write for atomic operations
      final batch = _firestore.batch();

      // Update borrowing status to active
      batch.update(_firestore.collection('borrowings').doc(borrowingId), {
        'status': 'active',
        'approvedBy': currentUser.uid,
        'approvedDate': FieldValue.serverTimestamp(),
        'borrowedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status to "In Use"
      batch.update(_firestore.collection('assets').doc(assetId), {
        'status': 'In Use',
        'borrowedBy': borrowingData['userId'],
        'borrowedAt': FieldValue.serverTimestamp(),
        'expectedReturnDate': borrowingData['expectedReturnDate'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Log activity
      await _logActivity(
        action: 'Borrow Request Approved',
        description: 'Approved borrowing: ${borrowingData['assetName']}',
        userId: borrowingData['userId'],
      );
    } catch (e) {
      throw Exception('Failed to approve borrow request: $e');
    }
  }

  // Admin rejects a borrow request
  Future<void> rejectBorrowRequest(String borrowingId, String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get borrowing details
      final borrowingDoc = await _firestore
          .collection('borrowings')
          .doc(borrowingId)
          .get();
      final borrowingData = borrowingDoc.data();

      if (borrowingData == null) {
        throw Exception('Borrowing request not found');
      }

      // Update borrowing status
      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'rejected',
        'rejectedBy': currentUser.uid,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(
        action: 'Borrow Request Rejected',
        description:
            'Rejected borrowing: ${borrowingData['assetName']} - Reason: $reason',
        userId: borrowingData['userId'],
      );
    } catch (e) {
      throw Exception('Failed to reject borrow request: $e');
    }
  }

  // ==================== RETURN ASSET ====================

  // User/Admin marks asset as returned
  Future<void> returnAsset(String borrowingId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get borrowing details
      final borrowingDoc = await _firestore
          .collection('borrowings')
          .doc(borrowingId)
          .get();
      final borrowingData = borrowingDoc.data();

      if (borrowingData == null) {
        throw Exception('Borrowing record not found');
      }

      final assetId = borrowingData['assetId'];

      // Start a batch write
      final batch = _firestore.batch();

      // Update borrowing status to returned
      batch.update(_firestore.collection('borrowings').doc(borrowingId), {
        'status': 'returned',
        'actualReturnDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status back to Available
      batch.update(_firestore.collection('assets').doc(assetId), {
        'status': 'Available',
        'borrowedBy': null,
        'borrowedAt': null,
        'expectedReturnDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Log activity
      await _logActivity(
        action: 'Asset Returned',
        description: 'Returned: ${borrowingData['assetName']}',
        userId: borrowingData['userId'],
      );
    } catch (e) {
      throw Exception('Failed to return asset: $e');
    }
  }

  // ==================== GET BORROWINGS ====================

  // Get all pending requests (for admin)
  Future<List<Borrowing>> getPendingRequests() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  // Get all active borrowings
  Future<List<Borrowing>> getActiveBorrowings() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'active')
          .orderBy('borrowedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active borrowings: $e');
    }
  }

  // Get user's borrowing history
  Future<List<Borrowing>> getUserBorrowings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user borrowings: $e');
    }
  }

  // Get current user's active borrowings
  Future<List<Borrowing>> getMyActiveBorrowings() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final snapshot = await _firestore
          .collection('borrowings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'active'])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active borrowings: $e');
    }
  }

  // Get overdue borrowings
  Future<List<Borrowing>> getOverdueBorrowings() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', isEqualTo: 'active')
          .where('expectedReturnDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('expectedReturnDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get overdue borrowings: $e');
    }
  }

  // Get all borrowings (for admin)
  Future<List<Borrowing>> getAllBorrowings() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all borrowings: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  // Log activity
  Future<void> _logActivity({
    required String action,
    required String description,
    String? userId,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'description': description,
        'userId': userId,
        'performedBy': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  // Get borrowing statistics
  Future<Map<String, int>> getBorrowingStats() async {
    try {
      final allBorrowings = await getAllBorrowings();

      int pending = 0;
      int active = 0;
      int overdue = 0;
      int returned = 0;

      for (var borrowing in allBorrowings) {
        switch (borrowing.status) {
          case 'pending':
            pending++;
            break;
          case 'active':
            active++;
            if (borrowing.isOverdue) {
              overdue++;
            }
            break;
          case 'returned':
            returned++;
            break;
        }
      }

      return {
        'pending': pending,
        'active': active,
        'overdue': overdue,
        'returned': returned,
        'total': allBorrowings.length,
      };
    } catch (e) {
      return {
        'pending': 0,
        'active': 0,
        'overdue': 0,
        'returned': 0,
        'total': 0,
      };
    }
  }
}
