import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/cyberpunk_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ZazaApp()));
}

class ZazaApp extends ConsumerWidget {
  const ZazaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Zaza Asset Management',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.theme,
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => Scaffold(
          backgroundColor: CyberpunkTheme.deepBlack,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: CyberpunkTheme.neonGlow(
                      CyberpunkTheme.primaryPink,
                    ),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CyberpunkTheme.primaryPink,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text('LOADING', style: CyberpunkTheme.neonText),
              ],
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: CyberpunkTheme.deepBlack,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: CyberpunkTheme.primaryPink,
                ),
                const SizedBox(height: 16),
                Text('ERROR', style: CyberpunkTheme.heading2),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: CyberpunkTheme.bodyText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
