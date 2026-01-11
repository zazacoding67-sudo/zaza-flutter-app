class UserReport {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final String status;

  UserReport({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    required this.status,
  });

  factory UserReport.fromMap(Map<String, dynamic> map) {
    return UserReport(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      createdAt: _parseDate(map['createdAt']),
      status: map['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
    };
  }
}

class AssetReport {
  final String id;
  final String name;
  final String category;
  final String status;
  final double value;
  final String location;
  final DateTime? createdAt;

  AssetReport({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.value,
    required this.location,
    this.createdAt,
  });

  factory AssetReport.fromMap(Map<String, dynamic> map) {
    return AssetReport(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      category: map['category']?.toString() ?? 'Other',
      status: map['status']?.toString() ?? 'Available',
      value: (map['value'] ?? 0).toDouble(),
      location: map['location']?.toString() ?? 'Unknown',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'value': value,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class BorrowingReport {
  final String id;
  final String assetName;
  final String userName;
  final String status;
  final DateTime? requestedDate;
  final DateTime? approvedDate;
  final DateTime? returnedDate;
  final DateTime? expectedReturnDate;

  BorrowingReport({
    required this.id,
    required this.assetName,
    required this.userName,
    required this.status,
    this.requestedDate,
    this.approvedDate,
    this.returnedDate,
    this.expectedReturnDate,
  });

  factory BorrowingReport.fromMap(Map<String, dynamic> map) {
    return BorrowingReport(
      id: map['id']?.toString() ?? '',
      assetName: map['assetName']?.toString() ?? 'Unknown',
      userName: map['userName']?.toString() ?? 'Unknown',
      status: map['status']?.toString() ?? 'pending',
      requestedDate: _parseDate(map['requestedDate']),
      approvedDate: _parseDate(map['approvedDate']),
      returnedDate: _parseDate(map['returnedDate']),
      expectedReturnDate: _parseDate(map['expectedReturnDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetName': assetName,
      'userName': userName,
      'status': status,
      'requestedDate': requestedDate?.toIso8601String(),
      'approvedDate': approvedDate?.toIso8601String(),
      'returnedDate': returnedDate?.toIso8601String(),
      'expectedReturnDate': expectedReturnDate?.toIso8601String(),
    };
  }
}

class ActivityReport {
  final String id;
  final String action;
  final String performedBy;
  final String performedByName;
  final Map<String, dynamic> details;
  final DateTime? timestamp;

  ActivityReport({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.details,
    this.timestamp,
  });

  factory ActivityReport.fromMap(Map<String, dynamic> map) {
    return ActivityReport(
      id: map['id']?.toString() ?? '',
      action: map['action']?.toString() ?? 'Unknown',
      performedBy: map['performedBy']?.toString() ?? 'System',
      performedByName: map['performedByName']?.toString() ?? 'System',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      timestamp: _parseDate(map['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'details': details,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

// Helper function to parse dates
DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;

  try {
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) return DateTime.tryParse(dateValue);
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);

    // Handle Firebase Timestamp format
    if (dateValue is Map) {
      if (dateValue['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue['seconds'] * 1000);
      }
    }

    return null;
  } catch (e) {
    return null;
  }
}
