import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String staffId;
  final String name;
  final String email;
  final String department;
  final String role; // 'admin', 'staff', or 'student'
  final String? phone;
  final String? photoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? createdBy;

  User({
    required this.id,
    required this.staffId,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    this.phone,
    this.photoUrl,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
    this.createdBy,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isStaff => role.toLowerCase() == 'staff';
  bool get isStudent => role.toLowerCase() == 'student';

  // FIXED: Accepts documentId parameter
  factory User.fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    return User(
      id: documentId ?? data['id'] ?? '',
      staffId: data['staffId'] ?? data['staff_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? 'student',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'staffId': staffId,
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'createdBy': createdBy,
    };
  }

  User copyWith({
    String? id,
    String? staffId,
    String? name,
    String? email,
    String? department,
    String? role,
    String? phone,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? createdBy,
  }) {
    return User(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
