import 'package:flutter/material.dart';

/// Colour tokens for a single [Brightness].
///
/// The dark palette is the original Ascended Athletics colourway
/// (electric purple on near-black). The light palette keeps the same purple
/// brand accents on lavender-tinted surfaces so both themes share the same
/// identity.
@immutable
class AppPalette {
  // Surfaces
  final Color primaryBackground;
  final Color secondarySurface;
  final Color cardSurface;

  // Interactive / brand accents
  final Color primaryAccent;
  final Color deepAccent;
  final Color lightAccent;

  // Text
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color onAccent;

  // Borders & dividers
  final Color border;
  final Color borderLight;

  // Feedback & status
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Tinted panels used by the Shopee-style surfaces.
  final Color softPanel;
  final Color softPanelAlt;

  const AppPalette({
    required this.primaryBackground,
    required this.secondarySurface,
    required this.cardSurface,
    required this.primaryAccent,
    required this.deepAccent,
    required this.lightAccent,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.onAccent,
    required this.border,
    required this.borderLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.softPanel,
    required this.softPanelAlt,
  });

  /// Original launch theme: purple on black.
  static const AppPalette dark = AppPalette(
    primaryBackground: Color(0xFF0B0B0F),
    secondarySurface: Color(0xFF17171F),
    cardSurface: Color(0xFF1E1E28),
    primaryAccent: Color(0xFF8B5CF6),
    deepAccent: Color(0xFF6D28D9),
    lightAccent: Color(0xFFA78BFA),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFA1A1AA),
    tertiaryText: Color(0xFF71717A),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFF27272A),
    borderLight: Color(0xFF3F3F46),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    softPanel: Color(0xFF221A38),
    softPanelAlt: Color(0xFF1A1A24),
  );

  /// Light counterpart with the same purple identity on lavender surfaces.
  static const AppPalette light = AppPalette(
    primaryBackground: Color(0xFFF7F5FB),
    secondarySurface: Color(0xFFFFFFFF),
    cardSurface: Color(0xFFF1EDF9),
    primaryAccent: Color(0xFF7C3AED),
    deepAccent: Color(0xFF5B21B6),
    lightAccent: Color(0xFF6D28D9),
    primaryText: Color(0xFF14121C),
    secondaryText: Color(0xFF565064),
    tertiaryText: Color(0xFF8A849B),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE4E0EE),
    borderLight: Color(0xFFD2CCE0),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    error: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    softPanel: Color(0xFFF0EAFE),
    softPanelAlt: Color(0xFFF3F0FA),
  );
}

/// Static accessors for the brand palette.
///
/// Widgets keep referring to `AppColors.primaryBackground` etc. The values are
/// resolved from the active [Brightness], which is updated by the root widget
/// whenever the user flips the Riverpod theme toggle. This keeps the hundreds
/// of existing call sites intact while still adapting every surface to the
/// light and dark themes.
class AppColors {
  AppColors._();

  /// Brand constants that are identical across both themes.
  static const Color brandPurple = Color(0xFF8B5CF6);
  static const Color brandBlack = Color(0xFF0B0B0F);

  static Brightness _brightness = Brightness.dark;

  static Brightness get brightness => _brightness;

  static bool get isDark => _brightness == Brightness.dark;

  /// Called by the root widget before a frame is built.
  static void applyBrightness(Brightness value) {
    _brightness = value;
  }

  static AppPalette of(Brightness value) =>
      value == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static AppPalette get palette => of(_brightness);

  // Surfaces
  static Color get primaryBackground => palette.primaryBackground;
  static Color get secondarySurface => palette.secondarySurface;
  static Color get cardSurface => palette.cardSurface;

  // Brand accents
  static Color get primaryAccent => palette.primaryAccent;
  static Color get deepAccent => palette.deepAccent;
  static Color get lightAccent => palette.lightAccent;

  // Text
  static Color get primaryText => palette.primaryText;
  static Color get secondaryText => palette.secondaryText;
  static Color get tertiaryText => palette.tertiaryText;
  static Color get onAccent => palette.onAccent;

  // Borders
  static Color get border => palette.border;
  static Color get borderLight => palette.borderLight;

  // Feedback
  static Color get success => palette.success;
  static Color get warning => palette.warning;
  static Color get error => palette.error;
  static Color get info => palette.info;

  // Legacy names kept for existing call sites.
  static Color get softGreen => palette.softPanel;
  static Color get softSand => palette.softPanelAlt;
}
