// Add this to your lib/providers/admin_providers.dart (or create a new borrowing_providers.dart)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/borrowing_service.dart';

// Borrowing Service Provider
final borrowingServiceProvider = Provider<BorrowingService>((ref) {
  return BorrowingService();
});

// Stream of pending requests
final pendingRequestsProvider = StreamProvider.autoDispose((ref) {
  final service = ref.watch(borrowingServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 5),
    (_) => service.getPendingRequests(),
  ).asyncMap((event) => event);
});

// Stream of active borrowings
final activeBorrowingsProvider = StreamProvider.autoDispose((ref) {
  final service = ref.watch(borrowingServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 5),
    (_) => service.getActiveBorrowings(),
  ).asyncMap((event) => event);
});

// Stream of user's active borrowings
final myActiveBorrowingsProvider = StreamProvider.autoDispose((ref) {
  final service = ref.watch(borrowingServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 5),
    (_) => service.getMyActiveBorrowings(),
  ).asyncMap((event) => event);
});
