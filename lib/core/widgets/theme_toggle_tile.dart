import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../../providers/theme_provider.dart';

/// Riverpod-driven dark/light switch, styled like the profile menu tiles.
///
/// Dark mode is the original Ascended Athletics colourway (electric purple on
/// black); light mode keeps the same purple accents on light surfaces.
class ThemeToggleTile extends ConsumerWidget {
  final EdgeInsetsGeometry margin;

  const ThemeToggleTile({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) != ThemeMode.light;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile.adaptive(
        value: isDark,
        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.primaryAccent,
            size: 20,
          ),
        ),
        title: Text(
          isDark ? 'Dark theme' : 'Light theme',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          isDark
              ? 'Original purple on black'
              : 'Purple accents on light surfaces',
          style: TextStyle(color: AppColors.tertiaryText, fontSize: 12),
        ),
      ),
    );
  }
}
