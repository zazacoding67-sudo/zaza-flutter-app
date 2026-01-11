// lib/screens/admin/reports/cache_service.dart
import 'package:flutter/foundation.dart';

class ReportCacheService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static DateTime? _lastUpdated;

  static Map<String, dynamic>? getCachedReports() {
    // Return cached data if it's less than 5 minutes old
    if (_lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < const Duration(minutes: 5)) {
      debugPrint('Returning cached reports');
      return _cache['allReports'];
    }
    debugPrint('Cache expired or not available');
    return null;
  }

  static void cacheReports(Map<String, dynamic> reports) {
    _cache['allReports'] = reports;
    _lastUpdated = DateTime.now();
    debugPrint('Reports cached at ${_lastUpdated}');
  }

  static void clearCache() {
    _cache.clear();
    _lastUpdated = null;
    debugPrint('Cache cleared');
  }

  static void cacheReport(String reportType, Map<String, dynamic> data) {
    _cache[reportType] = data;
    debugPrint('Cached report type: $reportType');
  }

  static Map<String, dynamic>? getCachedReport(String reportType) {
    return _cache[reportType];
  }
}
