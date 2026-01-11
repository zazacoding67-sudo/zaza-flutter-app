// lib/models/borrowing.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Borrowing {
  final String? id;
  final String assetId;
  final String assetName;
  final String borrowerId;
  final String borrowerName;
  final DateTime borrowedDate;
  final DateTime? returnedDate;
  final DateTime expectedReturnDate;
  final String status; // 'Borrowed', 'Returned', 'Overdue'
  final String? notes;

  Borrowing({
    this.id,
    required this.assetId,
    required this.assetName,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowedDate,
    this.returnedDate,
    required this.expectedReturnDate,
    this.status = 'Borrowed',
    this.notes,
  });

  factory Borrowing.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    return Borrowing(
      id: documentId,
      assetId: data['assetId'] ?? '',
      assetName: data['assetName'] ?? '',
      borrowerId: data['borrowerId'] ?? '',
      borrowerName: data['borrowerName'] ?? '',
      borrowedDate: (data['borrowedDate'] as Timestamp).toDate(),
      returnedDate: (data['returnedDate'] as Timestamp?)?.toDate(),
      expectedReturnDate: (data['expectedReturnDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'Borrowed',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'borrowedDate': Timestamp.fromDate(borrowedDate),
      'returnedDate': returnedDate != null
          ? Timestamp.fromDate(returnedDate!)
          : null,
      'expectedReturnDate': Timestamp.fromDate(expectedReturnDate),
      'status': status,
      'notes': notes,
    };
  }
}
