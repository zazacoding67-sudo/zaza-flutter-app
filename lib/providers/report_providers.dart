// lib/screens/admin/reports/providers/report_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Fixed import
import './report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final reportService = ref.read(reportServiceProvider);
  final filters = ref.watch(reportFiltersProvider);
  return await reportService.getAllStatistics(filters: filters);
});

final reportPeriodProvider = StateProvider<String>((ref) => 'All');

// filter providers
final reportFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Cached reports provider
final cachedReportsProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);
