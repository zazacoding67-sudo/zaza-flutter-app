import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to safely extract data from Firestore documents
  Map<String, dynamic> _getDataFromDoc(DocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? {};
  }

  // Helper method to safely extract data from QueryDocumentSnapshot
  Map<String, dynamic> _getDataFromQueryDoc(QueryDocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? {};
  }

  // Parse timestamp from Firestore
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get all statistics with optional filters
  Future<Map<String, dynamic>> getAllStatistics({
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Get counts using Firestore aggregation
      final usersCount = await _getUsersCount(filters);
      final assetsCount = await _getAssetsCount(filters);
      final activeBorrowingsCount = await _getActiveBorrowingsCount(filters);
      final availableAssetsCount = await _getAvailableAssetsCount(filters);

      // Get detailed data
      final recentUsers = await _getRecentUsers(5);
      final recentAssets = await _getRecentAssets(5);
      final recentBorrowings = await _getRecentBorrowings(5);
      final auditLogs = await _getAuditLogs(10);

      // Calculate utilization rate
      final utilizationRate = assetsCount > 0
          ? (activeBorrowingsCount / assetsCount) * 100
          : 0;

      return {
        'summary': {
          'totalUsers': usersCount,
          'totalAssets': assetsCount,
          'activeTransactions':
              activeBorrowingsCount, // Keep key for UI compatibility
          'availableAssets': availableAssetsCount,
          'utilizationRate': utilizationRate,
        },
        'recentData': {
          'users': recentUsers,
          'assets': recentAssets,
          'transactions': recentBorrowings, // Keep key for UI compatibility
        },
        'auditLogs': auditLogs,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'summary': {
          'totalUsers': 0,
          'totalAssets': 0,
          'activeTransactions': 0,
          'availableAssets': 0,
          'utilizationRate': 0.0,
        },
        'recentData': {'users': [], 'assets': [], 'transactions': []},
        'auditLogs': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get users count
  Future<int> _getUsersCount(Map<String, dynamic>? filters) async {
    try {
      Query query = _firestore.collection('users');

      // Apply filters if any
      if (filters != null && filters['userRole'] != null) {
        query = query.where('role', isEqualTo: filters['userRole']);
      }

      final snapshot = await query.get();
      return snapshot.size;
    } catch (e) {
      print('Error getting users count: $e');
      return 0;
    }
  }

  // Get assets count
  Future<int> _getAssetsCount(Map<String, dynamic>? filters) async {
    try {
      Query query = _firestore.collection('assets');

      // Apply filters if any
      if (filters != null) {
        if (filters['assetCategory'] != null) {
          query = query.where('category', isEqualTo: filters['assetCategory']);
        }
        if (filters['assetStatus'] != null) {
          query = query.where('status', isEqualTo: filters['assetStatus']);
        }
      }

      final snapshot = await query.get();
      return snapshot.size;
    } catch (e) {
      print('Error getting assets count: $e');
      return 0;
    }
  }

  // Get active borrowings count (instead of transactions)
  Future<int> _getActiveBorrowingsCount(Map<String, dynamic>? filters) async {
    try {
      Query query = _firestore
          .collection('borrowings')
          .where('status', whereIn: ['pending', 'approved', 'borrowed']);

      final snapshot = await query.get();
      return snapshot.size;
    } catch (e) {
      print('Error getting active borrowings count: $e');
      return 0;
    }
  }

  // Get available assets count
  Future<int> _getAvailableAssetsCount(Map<String, dynamic>? filters) async {
    try {
      Query query = _firestore
          .collection('assets')
          .where('status', isEqualTo: 'available');

      if (filters != null && filters['assetCategory'] != null) {
        query = query.where('category', isEqualTo: filters['assetCategory']);
      }

      final snapshot = await query.get();
      return snapshot.size;
    } catch (e) {
      print('Error getting available assets count: $e');
      return 0;
    }
  }

  // Get recent users
  Future<List<Map<String, dynamic>>> _getRecentUsers(int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = _getDataFromDoc(doc);
        return {
          'id': doc.id,
          'name':
              data['name'] ??
              data['displayName'] ??
              data['fullName'] ??
              'Unknown',
          'email': data['email'] ?? '',
          'role': data['role'] ?? data['userType'] ?? 'student',
          'createdAt': _formatDate(_parseTimestamp(data['createdAt'])),
          'status': data['isActive'] == true ? 'active' : 'inactive',
        };
      }).toList();
    } catch (e) {
      print('Error getting recent users: $e');
      return [];
    }
  }

  // Get recent assets
  Future<List<Map<String, dynamic>>> _getRecentAssets(int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('assets')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = _getDataFromQueryDoc(doc);
        return {
          'id': doc.id,
          'name': data['name'] ?? data['assetName'] ?? 'Unknown',
          'category': data['category'] ?? 'Other',
          'status': data['status'] ?? 'Available',
          'value': (data['purchasePrice'] ?? data['value'] ?? 0).toDouble(),
          'location': data['location'] ?? 'Unknown',
          'createdAt': _formatDate(_parseTimestamp(data['createdAt'])),
        };
      }).toList();
    } catch (e) {
      print('Error getting recent assets: $e');
      return [];
    }
  }

  // Get recent borrowings (instead of transactions)
  Future<List<Map<String, dynamic>>> _getRecentBorrowings(int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('borrowings')
          .orderBy('requestedDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = _getDataFromQueryDoc(doc);
        return {
          'id': doc.id,
          'assetName': data['assetName'] ?? data['assetId'] ?? 'Unknown',
          'userName': data['userName'] ?? data['userId'] ?? 'Unknown',
          'status': data['status'] ?? 'pending',
          'requestedDate': _formatDate(_parseTimestamp(data['requestedDate'])),
          'approvedDate': data['approvedDate'] != null
              ? _formatDate(_parseTimestamp(data['approvedDate']))
              : '-',
          'returnedDate': data['actualReturnDate'] != null
              ? _formatDate(_parseTimestamp(data['actualReturnDate']))
              : '-',
          'expectedReturnDate': data['expectedReturnDate'] != null
              ? _formatDate(_parseTimestamp(data['expectedReturnDate']))
              : '-',
        };
      }).toList();
    } catch (e) {
      print('Error getting recent borrowings: $e');
      return [];
    }
  }

  // Get audit logs
  Future<List<Map<String, dynamic>>> _getAuditLogs(int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = _getDataFromQueryDoc(doc);
        return {
          'id': doc.id,
          'action': data['action'] ?? 'Unknown',
          'performedBy': data['performedBy'] ?? 'System',
          'performedByName': data['performedByName'] ?? 'System',
          'details': data['details'] ?? {},
          'timestamp': _formatDate(_parseTimestamp(data['timestamp'])),
          'time': _parseTimestamp(data['timestamp']).toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('Error getting audit logs: $e');
      return [];
    }
  }

  // Export data to CSV
  Future<String> exportDataToCsv(
    String dataType,
    Map<String, dynamic>? filters,
  ) async {
    // Implementation for CSV export
    return 'CSV export not implemented yet';
  }

  // Get chart data for visualization
  Future<Map<String, dynamic>> getChartData(
    Map<String, dynamic>? filters,
  ) async {
    // Implementation for chart data
    return {};
  }

  // Get filtered reports
  Future<Map<String, dynamic>> getFilteredReports(
    Map<String, dynamic> filters,
  ) async {
    // Implementation for filtered reports
    return {};
  }
}
