// Save this as: lib/models/asset.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String name;
  final String category;
  final String description;
  final String serialNumber;
  final String purchaseDate;
  final double purchasePrice;
  final String location;
  final String status; // Available, In Use, Maintenance, Retired
  final String? borrowedBy;
  final DateTime? borrowedAt;
  final DateTime? expectedReturnDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.serialNumber,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.location,
    required this.status,
    this.borrowedBy,
    this.borrowedAt,
    this.expectedReturnDate,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Create Asset from Firestore document
  factory Asset.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    return Asset(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      serialNumber: data['serialNumber'] ?? '',
      purchaseDate: data['purchaseDate'] ?? '',
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      status: data['status'] ?? 'Available',
      borrowedBy: data['borrowedBy'],
      borrowedAt: data['borrowedAt'] != null
          ? (data['borrowedAt'] as Timestamp).toDate()
          : null,
      expectedReturnDate: data['expectedReturnDate'] != null
          ? (data['expectedReturnDate'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Asset to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate,
      'purchasePrice': purchasePrice,
      'location': location,
      'status': status,
      'borrowedBy': borrowedBy,
      'borrowedAt': borrowedAt,
      'expectedReturnDate': expectedReturnDate,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // CopyWith method for easy updates
  Asset copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? serialNumber,
    String? purchaseDate,
    double? purchasePrice,
    String? location,
    String? status,
    String? borrowedBy,
    DateTime? borrowedAt,
    DateTime? expectedReturnDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      location: location ?? this.location,
      status: status ?? this.status,
      borrowedBy: borrowedBy ?? this.borrowedBy,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
