// lib/services/memo_service.dart - Service for Memo Management
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memo.dart';

class MemoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'memos';

  // Send memo (broadcast or to specific student)
  Future<String> sendMemo({
    required String title,
    required String message,
    required String sentBy,
    required String sentByName,
    required String sentByRole,
    String? recipientId,
    String? recipientName,
    required MemoType type,
    required MemoPriority priority,
    DateTime? expiresAt,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final memo = Memo(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        sentBy: sentBy,
        sentByName: sentByName,
        sentByRole: sentByRole,
        recipientId: recipientId,
        recipientName: recipientName,
        type: type,
        priority: priority,
        sentAt: DateTime.now(),
        expiresAt: expiresAt,
        readBy: [],
        isActive: true,
        actionUrl: actionUrl,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(memo.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send memo: $e');
    }
  }

  // Get unread memos for a user
  Stream<List<Memo>> getUnreadMemosForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Memo.fromFirestore(doc.data(), documentId: doc.id))
              .where((memo) {
                // Filter: Not expired, and (broadcast OR for this user), and not read
                if (memo.isExpired) return false;
                final isForUser =
                    memo.recipientId == null || memo.recipientId == userId;
                final isUnread = !memo.isReadBy(userId);
                return isForUser && isUnread;
              })
              .toList();
        });
  }

  // Get all memos for a user (including read ones)
  Stream<List<Memo>> getAllMemosForUser(String userId, {int limit = 50}) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Memo.fromFirestore(doc.data(), documentId: doc.id))
              .where((memo) {
                // Filter: Not expired, and (broadcast OR for this user)
                if (memo.isExpired) return false;
                return memo.recipientId == null || memo.recipientId == userId;
              })
              .toList();
        });
  }

  // Mark memo as read
  Future<void> markAsRead(String memoId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(memoId);
      await docRef.update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark memo as read: $e');
    }
  }

  // Mark all memos as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all memos as read: $e');
    }
  }

  // Delete/deactivate memo (staff only)
  Future<void> deactivateMemo(String memoId) async {
    try {
      await _firestore.collection(_collection).doc(memoId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate memo: $e');
    }
  }

  // Get sent memos by staff
  Stream<List<Memo>> getSentMemos(String staffId) {
    return _firestore
        .collection(_collection)
        .where('sentBy', isEqualTo: staffId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Memo.fromFirestore(doc.data(), documentId: doc.id))
              .toList();
        });
  }

  // Get memo statistics
  Future<Map<String, int>> getMemoStats(String staffId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('sentBy', isEqualTo: staffId)
          .get();

      int total = snapshot.docs.length;
      int active = 0;
      int read = 0;

      for (var doc in snapshot.docs) {
        final memo = Memo.fromFirestore(doc.data(), documentId: doc.id);
        if (memo.isActive && !memo.isExpired) active++;
        if (memo.readBy.isNotEmpty) read++;
      }

      return {
        'total': total,
        'active': active,
        'read': read,
        'unread': total - read,
      };
    } catch (e) {
      return {'total': 0, 'active': 0, 'read': 0, 'unread': 0};
    }
  }
}
