// lib/models/asset.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String assetCode;
  final String name;
  final String category;
  final String description;
  final String? imageUrl;
  final String status; // 'available', 'borrowed', 'maintenance', 'retired'
  final String location;
  final String? assignedTo; // User ID if borrowed
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? manufacturer;
  final String? serialNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Asset({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.location,
    this.assignedTo,
    this.purchaseDate,
    this.purchasePrice,
    this.manufacturer,
    this.serialNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  bool get isAvailable => status == 'available';
  bool get isBorrowed => status == 'borrowed';

  factory Asset.fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    return Asset(
      id: documentId ?? data['id'] ?? '',
      assetCode: data['assetCode'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'available',
      location: data['location'] ?? '',
      assignedTo: data['assignedTo'],
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      manufacturer: data['manufacturer'],
      serialNumber: data['serialNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'assetCode': assetCode,
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'location': location,
      'assignedTo': assignedTo,
      'purchaseDate': purchaseDate != null
          ? Timestamp.fromDate(purchaseDate!)
          : null,
      'purchasePrice': purchasePrice,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Asset copyWith({
    String? id,
    String? assetCode,
    String? name,
    String? category,
    String? description,
    String? imageUrl,
    String? status,
    String? location,
    String? assignedTo,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? manufacturer,
    String? serialNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Asset(
      id: id ?? this.id,
      assetCode: assetCode ?? this.assetCode,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      location: location ?? this.location,
      assignedTo: assignedTo ?? this.assignedTo,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
