import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  String get _redirect =>
      GoRouterState.of(context).uri.queryParameters['redirect'] ?? '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .registerWithEmailAndPassword(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
          );
      ref.read(guestModeProvider.notifier).state = false;
      await ref.read(cartProvider.notifier).reloadForUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created. Welcome to Ascended Athletics!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (_redirect == 'checkout') {
        // Close register, then login (with success result) back to checkout.
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_redirect == 'checkout') {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text('CREATE ACCOUNT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'JOIN THE RANKS',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start shopping',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Full Name
                AuthTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Juan Dela Cruz',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Enter a valid name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

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
                const SizedBox(height: 18),

                // Phone (optional)
                AuthTextField(
                  controller: _phoneController,
                  label: 'Phone Number (optional)',
                  hint: '09XX XXX XXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),

                // Password
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimum 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
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
                const SizedBox(height: 18),

                // Confirm Password
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.onAccent,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('CREATE ACCOUNT'),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Already have an account?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
