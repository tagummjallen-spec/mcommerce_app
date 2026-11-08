import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';

/// Checks the current session, initializes services, then routes to
/// Home (authenticated or guest).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Give Firebase a moment and observe session state.
    try {
      final auth = ref.read(authServiceProvider);
      await Future.delayed(const Duration(milliseconds: 900));
      final User? user = auth.currentUser;
      if (user != null) {
        ref.read(guestModeProvider.notifier).state = false;
      } else {
        ref.read(guestModeProvider.notifier).state = true;
      }
    } catch (e) {
      // Firebase not configured yet: continue as guest so the UI can run.
      debugPrint('Session check failed: $e');
      ref.read(guestModeProvider.notifier).state = true;
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.primaryAccent,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName.toUpperCase(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: 3,
                    fontSize: 26,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
