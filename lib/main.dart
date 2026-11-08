import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';

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
    final themeMode = ref.watch(themeModeProvider);
    final brightness = ref.watch(themeBrightnessProvider);

    // Resolve the palette before the widget tree is built so every
    // `AppColors.*` access in this frame picks up the new mode. The
    // `PaletteScope` wrappers in the router listen to the same provider and
    // re-create the page subtrees, which is what makes screens that do not
    // depend on `Theme` repaint with the new colours.
    AppColors.applyBrightness(brightness);

    return MaterialApp.router(
      title: 'Ascended Athletics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
