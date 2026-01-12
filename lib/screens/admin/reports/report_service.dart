import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Parse timestamp from Firestore
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
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

  // ==================== MAIN METHOD ====================
  Future<Map<String, dynamic>> getAllStatistics({
    Map<String, dynamic>? filters,
  }) async {
    try {
      print('🔍 Fetching statistics from Firestore...');

      // Fetch all data in parallel
      final results = await Future.wait([
        _getUserStatistics(filters),
        _getAssetStatistics(filters),
        _getBorrowingStatistics(filters),
        _getActivityStatistics(filters),
      ]);

      final userStats = results[0];
      final assetStats = results[1];
      final borrowStats = results[2];
      final activityStats = results[3];

      print('✅ Statistics fetched successfully!');
      print('Users: ${userStats['total']}');
      print('Assets: ${assetStats['total']}');
      print('Borrowings: ${borrowStats['active']}');

      return {
        'users': userStats,
        'assets': assetStats,
        'borrowings': borrowStats,
        'activities': activityStats,
      };
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {
        'users': _emptyUserStats(),
        'assets': _emptyAssetStats(),
        'borrowings': _emptyBorrowingStats(),
        'activities': _emptyActivityStats(),
      };
    }
  }

  // ==================== USER STATISTICS ====================
  Future<Map<String, dynamic>> _getUserStatistics(
    Map<String, dynamic>? filters,
  ) async {
    try {
      Query query = _firestore.collection('users');

      // Apply role filter if provided
      if (filters != null && filters['userRole'] != null) {
        query = query.where('role', isEqualTo: filters['userRole']);
      }

      final snapshot = await query.get();
      final users = snapshot.docs;

      // Count by role
      final Map<String, int> byRole = {};
      int activeCount = 0;
      int inactiveCount = 0;

      for (var doc in users) {
        final data = doc.data() as Map<String, dynamic>;
        final role = (data['role'] ?? 'student').toString().toLowerCase();
        final isActive = data['isActive'] ?? true;

        byRole[role] = (byRole[role] ?? 0) + 1;

        if (isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }
      }

      // Get recent users (last 10)
      final recentUsersQuery = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final recentUsers = recentUsersQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['displayName'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'student',
          'createdAt': _parseTimestamp(data['createdAt']),
          'status': (data['isActive'] ?? true) ? 'active' : 'inactive',
        };
      }).toList();

      return {
        'total': users.length,
        'active': activeCount,
        'inactive': inactiveCount,
        'byRole': byRole.map((k, v) => MapEntry(k, v)),
        'recent': recentUsers,
      };
    } catch (e) {
      print('❌ Error in _getUserStatistics: $e');
      return _emptyUserStats();
    }
  }

  // ==================== ASSET STATISTICS ====================
  Future<Map<String, dynamic>> _getAssetStatistics(
    Map<String, dynamic>? filters,
  ) async {
    try {
      Query query = _firestore.collection('assets');

      // Apply filters
      if (filters != null) {
        if (filters['assetCategory'] != null) {
          query = query.where('category', isEqualTo: filters['assetCategory']);
        }
        if (filters['assetStatus'] != null) {
          query = query.where('status', isEqualTo: filters['assetStatus']);
        }
      }

      final snapshot = await query.get();
      final assets = snapshot.docs;

      // Count by category and status
      final Map<String, int> byCategory = {};
      final Map<String, int> byStatus = {};
      double totalValue = 0.0;
      int availableCount = 0;

      for (var doc in assets) {
        final data = doc.data() as Map<String, dynamic>;
        final category = (data['category'] ?? 'Other').toString();
        final status = (data['status'] ?? 'Available').toString();
        final value = (data['purchasePrice'] ?? data['value'] ?? 0).toDouble();

        byCategory[category] = (byCategory[category] ?? 0) + 1;
        byStatus[status] = (byStatus[status] ?? 0) + 1;
        totalValue += value;

        if (status.toLowerCase() == 'available') {
          availableCount++;
        }
      }

      // Get recent assets (last 10)
      final recentAssetsQuery = await _firestore
          .collection('assets')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final recentAssets = recentAssetsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['assetName'] ?? 'Unknown',
          'category': data['category'] ?? 'Other',
          'status': data['status'] ?? 'Available',
          'value': (data['purchasePrice'] ?? data['value'] ?? 0).toDouble(),
          'location': data['location'] ?? 'Unknown',
          'createdAt': _parseTimestamp(data['createdAt']),
        };
      }).toList();

      return {
        'total': assets.length,
        'available': availableCount,
        'inUse': byStatus['In Use'] ?? byStatus['in use'] ?? 0,
        'maintenance': byStatus['Maintenance'] ?? byStatus['maintenance'] ?? 0,
        'totalValue': totalValue,
        'byCategory': byCategory,
        'byStatus': byStatus,
        'recent': recentAssets,
      };
    } catch (e) {
      print('❌ Error in _getAssetStatistics: $e');
      return _emptyAssetStats();
    }
  }

  // ==================== BORROWING STATISTICS ====================
  Future<Map<String, dynamic>> _getBorrowingStatistics(
    Map<String, dynamic>? filters,
  ) async {
    try {
      final snapshot = await _firestore.collection('borrowings').get();
      final borrowings = snapshot.docs;

      int activeCount = 0;
      int pendingCount = 0;
      int returnedCount = 0;
      int overdueCount = 0;
      int rejectedCount = 0;

      // Monthly trends for chart (last 6 months)
      final now = DateTime.now();
      final Map<String, int> monthlyTrends = {};

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        monthlyTrends[monthKey] = 0;
      }

      for (var doc in borrowings) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final requestedDate = _parseTimestamp(data['requestedDate']);
        final expectedReturnDate = data['expectedReturnDate'] != null
            ? _parseTimestamp(data['expectedReturnDate'])
            : null;

        // Count by status
        if (status == 'active' ||
            status == 'borrowed' ||
            status == 'approved') {
          activeCount++;

          // Check if overdue
          if (expectedReturnDate != null &&
              expectedReturnDate.isBefore(DateTime.now())) {
            overdueCount++;
          }
        } else if (status == 'pending') {
          pendingCount++;
        } else if (status == 'returned' || status == 'completed') {
          returnedCount++;
        } else if (status == 'rejected' || status == 'cancelled') {
          rejectedCount++;
        }

        // Add to monthly trends
        final monthKey =
            '${requestedDate.year}-${requestedDate.month.toString().padLeft(2, '0')}';
        if (monthlyTrends.containsKey(monthKey)) {
          monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0) + 1;
        }
      }

      // Convert monthly trends to list format for chart
      final monthlyTrendsList = monthlyTrends.entries.map((entry) {
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final monthName = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][month - 1];

        return {'month': monthName, 'count': entry.value, 'year': year};
      }).toList();

      // Get recent borrowings (last 10)
      final recentBorrowingsQuery = await _firestore
          .collection('borrowings')
          .orderBy('requestedDate', descending: true)
          .limit(10)
          .get();

      final recentBorrowings = recentBorrowingsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'assetName': data['assetName'] ?? 'Unknown',
          'userName': data['userName'] ?? 'Unknown',
          'status': data['status'] ?? 'pending',
          'requestedDate': _parseTimestamp(data['requestedDate']),
          'approvedDate': data['approvedDate'] != null
              ? _parseTimestamp(data['approvedDate'])
              : null,
          'returnedDate': data['actualReturnDate'] != null
              ? _parseTimestamp(data['actualReturnDate'])
              : null,
          'expectedReturnDate': data['expectedReturnDate'] != null
              ? _parseTimestamp(data['expectedReturnDate'])
              : null,
        };
      }).toList();

      return {
        'total': borrowings.length,
        'active': activeCount,
        'pending': pendingCount,
        'returned': returnedCount,
        'overdue': overdueCount,
        'rejected': rejectedCount,
        'monthlyTrends': monthlyTrendsList,
        'recent': recentBorrowings,
      };
    } catch (e) {
      print('❌ Error in _getBorrowingStatistics: $e');
      return _emptyBorrowingStats();
    }
  }

  // ==================== ACTIVITY STATISTICS ====================
  Future<Map<String, dynamic>> _getActivityStatistics(
    Map<String, dynamic>? filters,
  ) async {
    try {
      // Try both collection names
      QuerySnapshot? snapshot;
      try {
        snapshot = await _firestore
            .collection('activity_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();
      } catch (e) {
        // Try audit_logs if activity_logs doesn't exist
        snapshot = await _firestore
            .collection('audit_logs')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();
      }

      final activities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'action': data['action'] ?? 'Unknown Action',
          'description': data['description'] ?? '',
          'performedBy': data['performedBy'] ?? 'System',
          'performedByName': data['performedByName'] ?? 'System',
          'userId': data['userId'],
          'timestamp': _parseTimestamp(data['timestamp']),
        };
      }).toList();

      return {'total': activities.length, 'recent': activities};
    } catch (e) {
      print('❌ Error in _getActivityStatistics: $e');
      return _emptyActivityStats();
    }
  }

  // ==================== EMPTY STATS ====================
  Map<String, dynamic> _emptyUserStats() {
    return {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'byRole': <String, int>{},
      'recent': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> _emptyAssetStats() {
    return {
      'total': 0,
      'available': 0,
      'inUse': 0,
      'maintenance': 0,
      'totalValue': 0.0,
      'byCategory': <String, int>{},
      'byStatus': <String, int>{},
      'recent': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> _emptyBorrowingStats() {
    return {
      'total': 0,
      'active': 0,
      'pending': 0,
      'returned': 0,
      'overdue': 0,
      'rejected': 0,
      'monthlyTrends': <Map<String, dynamic>>[],
      'recent': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> _emptyActivityStats() {
    return {'total': 0, 'recent': <Map<String, dynamic>>[]};
  }
}
