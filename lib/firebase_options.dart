import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Currently only Android is configured');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBoPx-pjTlM1kLSe-ktCEF4M0XDFos2qqs',
    appId: '1:977849821776:web:86575ca1cfff91398dff55',
    messagingSenderId: '977849821776',
    projectId: 'zaza-asset-management-fyp',
    authDomain: 'zaza-asset-management-fyp.firebaseapp.com',
    storageBucket: 'zaza-asset-management-fyp.firebasestorage.app',
    measurementId: 'G-HKR66J7XT7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoPx-pjTlM1kLSe-ktCEF4M0XDFos2qqs',
    appId: '1:977849821776:android:aef97b8761620ad8df55',
    messagingSenderId: '977849821776',
    projectId: 'zaza-asset-management-fyp',
    storageBucket: 'zaza-asset-management-fyp.firebasestorage.app',
  );
}
