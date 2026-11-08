import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// NOTE: Run `flutterfire configure` to replace the placeholder
/// lib/firebase_options.dart with this project's real Firebase options.
/// The app still boots (as guest) when Firebase is not configured yet.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Keep the app running so the UI can be demonstrated even before
    // Firebase is configured; Firestore/Auth calls will surface errors.
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: AscendedAthleticsApp()));
}

class AscendedAthleticsApp extends ConsumerWidget {
  const AscendedAthleticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ascended Athletics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
