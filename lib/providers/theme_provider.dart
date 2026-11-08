import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the active [ThemeMode] for the storefront.
///
/// The default is [ThemeMode.dark], which restores the original Ascended
/// Athletics purple-on-black colourway.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  bool get isDark => state != ThemeMode.light;

  void toggle() {
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Convenience helper so widgets can resolve the current [Brightness].
final themeBrightnessProvider = Provider<Brightness>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.light ? Brightness.light : Brightness.dark;
});
