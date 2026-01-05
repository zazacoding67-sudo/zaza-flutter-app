// auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// For Firebase User auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// For your app User (with role)
final appUserProvider = FutureProvider.autoDispose<app_user.User?>((ref) async {
  final authService = ref.watch(authServiceProvider);

  // Get current Firebase user
  final currentUser = authService.getCurrentUser();
  if (currentUser == null) return null;

  // Get app user data from Firestore
  return await authService.getUserData(currentUser.uid);
});
