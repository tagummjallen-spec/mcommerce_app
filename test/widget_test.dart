import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/core/constants/app_colors.dart';
import 'package:mcommerce_app/core/theme/app_theme.dart';
import 'package:mcommerce_app/providers/theme_provider.dart';

void main() {
  testWidgets('dark theme is the original purple-on-black colourway', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Center(child: Text('Ascended Athletics'))),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppPalette.dark.primaryBackground,
    );
    expect(Theme.of(context).colorScheme.primary, const Color(0xFF8B5CF6));
    expect(find.text('Ascended Athletics'), findsOneWidget);
  });

  testWidgets('light theme keeps the purple accents on light surfaces', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('Ascended Athletics'))),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppPalette.light.primaryBackground,
    );
    expect(
      Theme.of(context).colorScheme.primary,
      AppPalette.light.primaryAccent,
    );
  });

  test('theme toggle defaults to dark and flips to light', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(container.read(themeBrightnessProvider), Brightness.dark);

    container.read(themeModeProvider.notifier).toggle();

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(container.read(themeBrightnessProvider), Brightness.light);
  });

  test('AppColors resolves tokens from the active brightness', () {
    addTearDown(() => AppColors.applyBrightness(Brightness.dark));

    AppColors.applyBrightness(Brightness.dark);
    expect(AppColors.primaryBackground, AppPalette.dark.primaryBackground);
    expect(AppColors.primaryText, AppPalette.dark.primaryText);

    AppColors.applyBrightness(Brightness.light);
    expect(AppColors.primaryBackground, AppPalette.light.primaryBackground);
    expect(AppColors.primaryText, AppPalette.light.primaryText);
  });
}
