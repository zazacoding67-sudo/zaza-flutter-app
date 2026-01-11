// Save this as: lib/models/borrowing.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Borrowing {
  final String id;
  final String assetId;
  final String assetName;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime requestedDate;
  final DateTime? approvedDate;
  final DateTime? borrowedDate;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status; // pending, approved, active, returned, rejected
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectionReason;
  final String purpose;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Borrowing({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.requestedDate,
    this.approvedDate,
    this.borrowedDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.approvedBy,
    this.rejectedBy,
    this.rejectionReason,
    required this.purpose,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore
  factory Borrowing.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    return Borrowing(
      id: documentId,
      assetId: data['assetId'] ?? '',
      assetName: data['assetName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      requestedDate: data['requestedDate'] != null
          ? (data['requestedDate'] as Timestamp).toDate()
          : DateTime.now(),
      approvedDate: data['approvedDate'] != null
          ? (data['approvedDate'] as Timestamp).toDate()
          : null,
      borrowedDate: data['borrowedDate'] != null
          ? (data['borrowedDate'] as Timestamp).toDate()
          : null,
      expectedReturnDate: data['expectedReturnDate'] != null
          ? (data['expectedReturnDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 7)),
      actualReturnDate: data['actualReturnDate'] != null
          ? (data['actualReturnDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      approvedBy: data['approvedBy'],
      rejectedBy: data['rejectedBy'],
      rejectionReason: data['rejectionReason'],
      purpose: data['purpose'] ?? '',
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'approvedDate': approvedDate != null
          ? Timestamp.fromDate(approvedDate!)
          : null,
      'borrowedDate': borrowedDate != null
          ? Timestamp.fromDate(borrowedDate!)
          : null,
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'actualReturnDate': actualReturnDate != null
          ? Timestamp.fromDate(actualReturnDate!)
          : null,
      'status': status,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'rejectionReason': rejectionReason,
      'purpose': purpose,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Check if borrowing is overdue
  bool get isOverdue {
    if (status != 'active' && status != 'Borrowed') return false;
    return DateTime.now().isAfter(expectedReturnDate);
  }

  // Get days until due
  int get daysUntilDue {
    return expectedReturnDate.difference(DateTime.now()).inDays;
  }

  // Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(expectedReturnDate).inDays;
  }

  // CopyWith method
  Borrowing copyWith({
    String? id,
    String? assetId,
    String? assetName,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? requestedDate,
    DateTime? approvedDate,
    DateTime? borrowedDate,
    DateTime? expectedReturnDate,
    DateTime? actualReturnDate,
    String? status,
    String? approvedBy,
    String? rejectedBy,
    String? rejectionReason,
    String? purpose,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Borrowing(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      requestedDate: requestedDate ?? this.requestedDate,
      approvedDate: approvedDate ?? this.approvedDate,
      borrowedDate: borrowedDate ?? this.borrowedDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
