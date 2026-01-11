import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../theme/cyberpunk_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        // ← FIXED: Changed from signInWithEmailAndPassword
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: CyberpunkTheme.primaryPink,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.deepBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: CyberpunkTheme.pinkPurpleGradient,
                    boxShadow: CyberpunkTheme.neonGlow(
                      CyberpunkTheme.primaryPink,
                      intensity: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'ZAZA ASSET',
                  style: CyberpunkTheme.heading1.copyWith(fontSize: 36),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      CyberpunkTheme.pinkPurpleGradient.createShader(bounds),
                  child: Text(
                    'MANAGEMENT SYSTEM',
                    style: CyberpunkTheme.heading3.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48),

                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.surfaceDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CyberpunkTheme.primaryPink.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CyberpunkTheme.primaryPink.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM LOGIN',
                          style: CyberpunkTheme.heading2.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        Text(
                          'EMAIL',
                          style: CyberpunkTheme.bodyText.copyWith(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: CyberpunkTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: CyberpunkTheme.bodyText,
                          decoration: InputDecoration(
                            hintText: 'user@zaza.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: CyberpunkTheme.primaryPink,
                            ),
                            filled: true,
                            fillColor: CyberpunkTheme.deepBlack.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: CyberpunkTheme.primaryPink,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: CyberpunkTheme.primaryPink.withOpacity(
                                  0.5,
                                ),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: CyberpunkTheme.primaryPink,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Password Field
                        Text(
                          'PASSWORD',
                          style: CyberpunkTheme.bodyText.copyWith(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: CyberpunkTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: CyberpunkTheme.bodyText,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: CyberpunkTheme.primaryPink,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: CyberpunkTheme.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: CyberpunkTheme.deepBlack.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: CyberpunkTheme.primaryPink,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: CyberpunkTheme.primaryPink.withOpacity(
                                  0.5,
                                ),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: CyberpunkTheme.primaryPink,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: CyberpunkTheme.pinkPurpleGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: CyberpunkTheme.neonGlow(
                                CyberpunkTheme.primaryPink,
                                intensity: 0.8,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.login, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'SIGN IN',
                                          style: CyberpunkTheme.buttonText,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                Text(
                  '© 2024 ZAZA ASSET MANAGEMENT',
                  style: CyberpunkTheme.bodyText.copyWith(
                    fontSize: 11,
                    color: CyberpunkTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
