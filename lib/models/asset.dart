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
  final String? assetCode;

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
    this.assetCode,
  });

  // Computed property - derive isAvailable from status
  bool get isAvailable => status.toLowerCase() == 'available';

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
      status: _normalizeStatus(data['status'] ?? 'Available'),
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
      assetCode: data['assetCode'] ?? data['serialNumber'],
    );
  }

  // Normalize status to prevent issues
  static String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus.contains('available')) return 'Available';
    if (lowerStatus.contains('loan') ||
        lowerStatus.contains('borrowed') ||
        lowerStatus.contains('in use'))
      return 'In Use';
    if (lowerStatus.contains('maintenance')) return 'Maintenance';
    if (lowerStatus.contains('retired')) return 'Retired';

    return 'Available'; // Default
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
      'isAvailable': isAvailable, // Keep for compatibility
      'borrowedBy': borrowedBy,
      'borrowedAt': borrowedAt != null ? Timestamp.fromDate(borrowedAt!) : null,
      'expectedReturnDate': expectedReturnDate != null
          ? Timestamp.fromDate(expectedReturnDate!)
          : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assetCode': assetCode ?? serialNumber,
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
    String? assetCode,
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
      assetCode: assetCode ?? this.assetCode,
    );
  }

  // Mark as borrowed
  Asset markAsBorrowed(String userId, DateTime expectedReturn) {
    return copyWith(
      status: 'In Use',
      borrowedBy: userId,
      borrowedAt: DateTime.now(),
      expectedReturnDate: expectedReturn,
      updatedAt: DateTime.now(),
    );
  }

  // Mark as returned
  Asset markAsReturned() {
    return copyWith(
      status: 'Available',
      borrowedBy: null,
      borrowedAt: null,
      expectedReturnDate: null,
      updatedAt: DateTime.now(),
    );
  }
}
