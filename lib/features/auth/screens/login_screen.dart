import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../widgets/auth_text_field.dart';

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
  final bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _redirect =>
      GoRouterState.of(context).uri.queryParameters['redirect'] ?? '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .loginWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      ref.read(guestModeProvider.notifier).state = false;
      // Load/merge the user's Firestore cart into state.
      await ref.read(cartProvider.notifier).reloadForUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, warrior!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (_redirect == 'checkout') {
        // Return to the checkout screen that pushed this login page.
        context.pop(true);
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    ref.read(guestModeProvider.notifier).state = true;
    ref.read(cartProvider.notifier).resetToEmpty();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand mark
                  Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: AppColors.primaryAccent,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'WELCOME BACK',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your ascent',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Email
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppColors.lightAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.onAccent,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('LOGIN'),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Guest entry
                  OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('CONTINUE AS GUEST'),
                  ),
                  const SizedBox(height: 28),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "New to ${AppConstants.appName}?",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_redirect == 'checkout') {
                            context.push('/register?redirect=checkout');
                          } else {
                            context.go('/register');
                          }
                        },
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        title: Text(
          'Reset Password',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email and we will send you a reset link.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              try {
                await ref.read(authServiceProvider).resetPassword(email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
