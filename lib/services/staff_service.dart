// lib/services/staff_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/asset.dart';
import '../models/borrowing.dart';
import '../models/user.dart' as app_user;

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // ==================== BORROWING MANAGEMENT ====================

  // Get pending borrowing requests
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

  // Approve borrowing request
  Future<void> approveBorrowingRequest(
    String borrowingId,
    String assetId, {
    String? notes,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      if (staffId == null) throw Exception('Not authenticated');

      final batch = _firestore.batch();

      // Update borrowing status
      batch.update(_firestore.collection('borrowings').doc(borrowingId), {
        'status': 'approved',
        'approvedBy': staffId,
        'approvedDate': FieldValue.serverTimestamp(),
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status
      batch.update(_firestore.collection('assets').doc(assetId), {
        'status': 'In Use',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Log activity
      await _logStaffActivity(
        action: 'Approved Borrowing',
        description: 'Approved borrowing request #$borrowingId',
        relatedId: borrowingId,
      );
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  // Reject borrowing request
  Future<void> rejectBorrowingRequest(String borrowingId, String reason) async {
    try {
      final staffId = _auth.currentUser?.uid;
      if (staffId == null) throw Exception('Not authenticated');

      await _firestore.collection('borrowings').doc(borrowingId).update({
        'status': 'rejected',
        'rejectedBy': staffId,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logStaffActivity(
        action: 'Rejected Borrowing',
        description: 'Rejected borrowing request #$borrowingId: $reason',
        relatedId: borrowingId,
      );
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  // Get active borrowings
  Future<List<Borrowing>> getActiveBorrowings() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', whereIn: ['approved', 'active'])
          .orderBy('expectedReturnDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Borrowing.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active borrowings: $e');
    }
  }

  // Process return
  Future<void> processReturn(
    String borrowingId,
    String assetId, {
    String? condition,
    String? damageNotes,
    bool requiresMaintenance = false,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      if (staffId == null) throw Exception('Not authenticated');

      final batch = _firestore.batch();

      // Update borrowing record
      batch.update(_firestore.collection('borrowings').doc(borrowingId), {
        'status': 'returned',
        'actualReturnDate': FieldValue.serverTimestamp(),
        'returnCondition': condition,
        'damageNotes': damageNotes,
        'processedBy': staffId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update asset status
      final newAssetStatus = requiresMaintenance ? 'Maintenance' : 'Available';
      batch.update(_firestore.collection('assets').doc(assetId), {
        'status': newAssetStatus,
        'lastInspectionDate': FieldValue.serverTimestamp(),
        'lastInspectionBy': staffId,
        'condition': condition,
        'borrowedBy': null,
        'borrowedAt': null,
        'expectedReturnDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If damaged, create maintenance record
      if (requiresMaintenance) {
        batch.set(_firestore.collection('maintenance_records').doc(), {
          'assetId': assetId,
          'type': 'damage_inspection',
          'condition': condition,
          'notes': damageNotes,
          'reportedBy': staffId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Log activity
      await _logStaffActivity(
        action: 'Processed Return',
        description: 'Processed return for borrowing #$borrowingId',
        relatedId: borrowingId,
      );
    } catch (e) {
      throw Exception('Failed to process return: $e');
    }
  }

  // ==================== ASSET INVENTORY MANAGEMENT ====================

  // Get all assets with detailed info
  Future<List<Asset>> getAllAssetsForInventory() async {
    try {
      final snapshot = await _firestore
          .collection('assets')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Asset.fromFirestore(doc.data(), documentId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get assets: $e');
    }
  }

  // Update asset condition
  Future<void> updateAssetCondition(
    String assetId, {
    required String condition,
    String? notes,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      if (staffId == null) throw Exception('Not authenticated');

      await _firestore.collection('assets').doc(assetId).update({
        'condition': condition,
        'lastInspectionDate': FieldValue.serverTimestamp(),
        'lastInspectionBy': staffId,
        'conditionNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logStaffActivity(
        action: 'Updated Asset Condition',
        description: 'Updated condition for asset #$assetId to $condition',
        relatedId: assetId,
      );
    } catch (e) {
      throw Exception('Failed to update asset condition: $e');
    }
  }

  // Report asset issue
  Future<void> reportAssetIssue(
    String assetId,
    String assetName, {
    required String issueType,
    required String description,
    String? urgency,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      if (staffId == null) throw Exception('Not authenticated');

      // Create maintenance record
      await _firestore.collection('maintenance_records').add({
        'assetId': assetId,
        'assetName': assetName,
        'type': issueType,
        'description': description,
        'urgency': urgency ?? 'medium',
        'reportedBy': staffId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update asset status if urgent
      if (urgency == 'high' || urgency == 'critical') {
        await _firestore.collection('assets').doc(assetId).update({
          'status': 'Maintenance',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log activity
      await _logStaffActivity(
        action: 'Reported Asset Issue',
        description: 'Reported $issueType issue for $assetName',
        relatedId: assetId,
      );
    } catch (e) {
      throw Exception('Failed to report asset issue: $e');
    }
  }

  // ==================== STAFF STATISTICS ====================

  // Get staff operational statistics
  Future<Map<String, dynamic>> getStaffStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
      final thisMonthStart = DateTime(now.year, now.month, 1);

      // Get all borrowings
      final borrowingsSnapshot = await _firestore
          .collection('borrowings')
          .get();

      // Get all assets
      final assetsSnapshot = await _firestore.collection('assets').get();

      // Calculate statistics
      int pendingRequests = 0;
      int activeBorrowings = 0;
      int overdueItems = 0;
      int todayReturns = 0;
      int weeklyApprovals = 0;
      int monthlyReturns = 0;

      for (var doc in borrowingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final expectedReturnDate = (data['expectedReturnDate'] as Timestamp?)
            ?.toDate();
        final approvedDate = (data['approvedDate'] as Timestamp?)?.toDate();
        final actualReturnDate = (data['actualReturnDate'] as Timestamp?)
            ?.toDate();

        if (status == 'pending') {
          pendingRequests++;
        } else if (status == 'approved' || status == 'active') {
          activeBorrowings++;

          // Check if overdue
          if (expectedReturnDate != null && expectedReturnDate.isBefore(now)) {
            overdueItems++;
          }

          // Check if due today
          if (expectedReturnDate != null &&
              expectedReturnDate.year == today.year &&
              expectedReturnDate.month == today.month &&
              expectedReturnDate.day == today.day) {
            todayReturns++;
          }
        }

        // Weekly approvals
        if (approvedDate != null && approvedDate.isAfter(thisWeekStart)) {
          weeklyApprovals++;
        }

        // Monthly returns
        if (actualReturnDate != null &&
            actualReturnDate.isAfter(thisMonthStart)) {
          monthlyReturns++;
        }
      }

      // Asset statistics
      int availableAssets = 0;
      int inUseAssets = 0;
      int maintenanceAssets = 0;
      int lowStockCategories = 0;

      final categoryCount = <String, Map<String, int>>{};

      for (var doc in assetsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final category = data['category'] as String? ?? 'Uncategorized';

        // Count by status
        switch (status) {
          case 'Available':
            availableAssets++;
            break;
          case 'In Use':
            inUseAssets++;
            break;
          case 'Maintenance':
            maintenanceAssets++;
            break;
        }

        // Count by category
        if (!categoryCount.containsKey(category)) {
          categoryCount[category] = {'total': 0, 'available': 0};
        }
        categoryCount[category]!['total'] =
            (categoryCount[category]!['total'] ?? 0) + 1;
        if (status == 'Available') {
          categoryCount[category]!['available'] =
              (categoryCount[category]!['available'] ?? 0) + 1;
        }
      }

      // Check for low stock (less than 3 available in category)
      categoryCount.forEach((category, counts) {
        if ((counts['available'] ?? 0) < 3) {
          lowStockCategories++;
        }
      });

      return {
        // Borrowing stats
        'pendingRequests': pendingRequests,
        'activeBorrowings': activeBorrowings,
        'overdueItems': overdueItems,
        'todayReturns': todayReturns,
        'weeklyApprovals': weeklyApprovals,
        'monthlyReturns': monthlyReturns,

        // Asset stats
        'totalAssets': assetsSnapshot.docs.length,
        'availableAssets': availableAssets,
        'inUseAssets': inUseAssets,
        'maintenanceAssets': maintenanceAssets,
        'lowStockCategories': lowStockCategories,

        // Category breakdown
        'categoryBreakdown': categoryCount,
      };
    } catch (e) {
      throw Exception('Failed to get staff statistics: $e');
    }
  }

  // Get overdue borrowings
  Future<List<Borrowing>> getOverdueBorrowings() async {
    try {
      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', whereIn: ['approved', 'active'])
          .get();

      final now = DateTime.now();
      final overdue = <Borrowing>[];

      for (var doc in snapshot.docs) {
        final borrowing = Borrowing.fromFirestore(
          doc.data(),
          documentId: doc.id,
        );
        if (borrowing.expectedReturnDate.isBefore(now)) {
          overdue.add(borrowing);
        }
      }

      // Sort by most overdue first
      overdue.sort(
        (a, b) => a.expectedReturnDate.compareTo(b.expectedReturnDate),
      );

      return overdue;
    } catch (e) {
      throw Exception('Failed to get overdue borrowings: $e');
    }
  }

  // Send reminder notification
  Future<void> sendReturnReminder(String borrowingId, String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'return_reminder',
        'title': 'Return Reminder',
        'message': 'Please return your borrowed item soon.',
        'borrowingId': borrowingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logStaffActivity(
        action: 'Sent Return Reminder',
        description: 'Sent return reminder for borrowing #$borrowingId',
        relatedId: borrowingId,
      );
    } catch (e) {
      throw Exception('Failed to send reminder: $e');
    }
  }

  // ==================== QUICK ACTIONS ====================

  // Get today's scheduled returns
  Future<List<Borrowing>> getTodayScheduledReturns() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('borrowings')
          .where('status', whereIn: ['approved', 'active'])
          .get();

      final todayReturns = <Borrowing>[];

      for (var doc in snapshot.docs) {
        final borrowing = Borrowing.fromFirestore(
          doc.data(),
          documentId: doc.id,
        );
        if (borrowing.expectedReturnDate.isAfter(today) &&
            borrowing.expectedReturnDate.isBefore(tomorrow)) {
          todayReturns.add(borrowing);
        }
      }

      return todayReturns;
    } catch (e) {
      throw Exception('Failed to get today\'s returns: $e');
    }
  }

  // Get maintenance alerts
  Future<List<Map<String, dynamic>>> getMaintenanceAlerts() async {
    try {
      final snapshot = await _firestore
          .collection('maintenance_records')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Failed to get maintenance alerts: $e');
    }
  }

  // ==================== ACTIVITY LOGGING ====================

  Future<void> _logStaffActivity({
    required String action,
    required String description,
    String? relatedId,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      await _firestore.collection('activity_logs').add({
        'action': action,
        'description': description,
        'performedBy': staffId,
        'relatedId': relatedId,
        'userRole': 'staff',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to log staff activity: $e');
    }
  }

  // Get staff activity history
  Future<List<Map<String, dynamic>>> getStaffActivityHistory({
    int limit = 50,
  }) async {
    try {
      final staffId = _auth.currentUser?.uid;
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('performedBy', isEqualTo: staffId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Failed to get activity history: $e');
    }
  }
}
