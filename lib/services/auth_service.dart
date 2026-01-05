// auth_service.dart - FIXED VERSION
import 'package:flutter/foundation.dart'; // ← ADD THIS LINE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<app_user.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e'); // Now this will work
      return null;
    }
  }

  Future<app_user.User?> getCurrentAppUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;
    return await getUserData(currentUser.uid);
  }

  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}'); // Now this will work
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }
}
