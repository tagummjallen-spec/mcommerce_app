import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/core/constants/app_colors.dart';
import 'package:mcommerce_app/core/widgets/palette_scope.dart';
import 'package:mcommerce_app/providers/theme_provider.dart';

/// Stand-in for a storefront page: it reads the runtime [AppColors] tokens in
/// `build` without depending on `Theme` (as every screen does).
class _StalePage extends StatelessWidget {
  const _StalePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Text('page', style: TextStyle(color: AppColors.primaryText)),
    );
  }
}

/// Mirrors `AscendedAthleticsApp`: applies the palette from Riverpod and then
/// builds the router content wrapped in a [PaletteScope].
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppColors.applyBrightness(ref.watch(themeBrightnessProvider));
    return const MaterialApp(home: PaletteScope(child: _StalePage()));
  }
}

void main() {
  testWidgets('PaletteScope rebuilds page content when the theme flips', (
    WidgetTester tester,
  ) async {
    addTearDown(() => AppColors.applyBrightness(Brightness.dark));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppPalette.dark.primaryBackground,
    );

    container.read(themeModeProvider.notifier).toggle();
    await tester.pumpAndSettle();

    // The page itself must have rebuilt with the light palette, even though it
    // never depends on `Theme`.
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppPalette.light.primaryBackground,
    );
    final Text text = tester.widget<Text>(find.text('page'));
    expect(text.style?.color, AppPalette.light.primaryText);

    container.read(themeModeProvider.notifier).toggle();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppPalette.dark.primaryBackground,
    );
  });
}
