// lib/models/memo.dart - New Memo Model for Staff Notifications
import 'package:cloud_firestore/cloud_firestore.dart';

class Memo {
  final String id;
  final String title;
  final String message;
  final String sentBy; // Staff user ID
  final String sentByName; // Staff name
  final String sentByRole; // staff/admin
  final String? recipientId; // null = broadcast to all students
  final String? recipientName;
  final MemoType type; // info, warning, urgent, announcement
  final MemoPriority priority; // low, normal, high, urgent
  final DateTime sentAt;
  final DateTime? expiresAt;
  final List<String> readBy; // User IDs who have read
  final bool isActive;
  final String? actionUrl; // Optional link/action
  final Map<String, dynamic>? metadata; // Additional data

  Memo({
    required this.id,
    required this.title,
    required this.message,
    required this.sentBy,
    required this.sentByName,
    required this.sentByRole,
    this.recipientId,
    this.recipientName,
    required this.type,
    required this.priority,
    required this.sentAt,
    this.expiresAt,
    required this.readBy,
    this.isActive = true,
    this.actionUrl,
    this.metadata,
  });

  // Check if memo is read by user
  bool isReadBy(String userId) => readBy.contains(userId);

  // Check if expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if should show (active and not expired)
  bool get shouldShow => isActive && !isExpired;

  // From Firestore
  factory Memo.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    return Memo(
      id: documentId,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      sentBy: data['sentBy'] ?? '',
      sentByName: data['sentByName'] ?? 'Staff',
      sentByRole: data['sentByRole'] ?? 'staff',
      recipientId: data['recipientId'],
      recipientName: data['recipientName'],
      type: MemoType.fromString(data['type'] ?? 'info'),
      priority: MemoPriority.fromString(data['priority'] ?? 'normal'),
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      readBy: data['readBy'] != null ? List<String>.from(data['readBy']) : [],
      isActive: data['isActive'] ?? true,
      actionUrl: data['actionUrl'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'sentBy': sentBy,
      'sentByName': sentByName,
      'sentByRole': sentByRole,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'type': type.value,
      'priority': priority.value,
      'sentAt': Timestamp.fromDate(sentAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'readBy': readBy,
      'isActive': isActive,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }

  // Mark as read
  Memo markAsRead(String userId) {
    if (!readBy.contains(userId)) {
      return Memo(
        id: id,
        title: title,
        message: message,
        sentBy: sentBy,
        sentByName: sentByName,
        sentByRole: sentByRole,
        recipientId: recipientId,
        recipientName: recipientName,
        type: type,
        priority: priority,
        sentAt: sentAt,
        expiresAt: expiresAt,
        readBy: [...readBy, userId],
        isActive: isActive,
        actionUrl: actionUrl,
        metadata: metadata,
      );
    }
    return this;
  }
}

// Memo Types
enum MemoType {
  info('info'),
  warning('warning'),
  urgent('urgent'),
  announcement('announcement');

  final String value;
  const MemoType(this.value);

  static MemoType fromString(String value) {
    return MemoType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoType.info,
    );
  }
}

// Memo Priority
enum MemoPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  final String value;
  const MemoPriority(this.value);

  static MemoPriority fromString(String value) {
    return MemoPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MemoPriority.normal,
    );
  }
}
