import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Ascended Athletics themes.
///
/// [darkTheme] is the original purple-on-black colourway and is the default.
/// [lightTheme] keeps the same purple accents on lavender surfaces. Both are
/// generated from an explicit [AppPalette] so they never depend on the
/// mutable global state used by [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);

  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primaryAccent,
      onPrimary: c.onAccent,
      secondary: c.lightAccent,
      onSecondary: c.onAccent,
      error: c.error,
      onError: c.onAccent,
      surface: c.secondarySurface,
      onSurface: c.primaryText,
      outline: c.borderLight,
      outlineVariant: c.border,
      surfaceContainerHighest: c.cardSurface,
    );

    final baseText = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: -0.6,
        ),
        displayMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.4,
        ),
        headlineLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 21,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: c.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: c.primaryText, fontSize: 16),
        bodyMedium: TextStyle(color: c.secondaryText, fontSize: 14),
        bodySmall: TextStyle(color: c.tertiaryText, fontSize: 12),
        labelSmall: TextStyle(
          color: c.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.primaryBackground,
      canvasColor: c.primaryBackground,
      colorScheme: colorScheme,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: c.primaryBackground,
        foregroundColor: c.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.primaryText),
        titleTextStyle: TextStyle(
          color: c.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.secondarySurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.secondarySurface,
        hintStyle: TextStyle(color: c.tertiaryText, fontSize: 14),
        labelStyle: TextStyle(color: c.secondaryText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primaryAccent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.borderLight,
          disabledForegroundColor: c.onAccent.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
          elevation: 0,
          minimumSize: const Size(0, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaryAccent,
          side: BorderSide(color: c.primaryAccent, width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(0, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primaryAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.secondarySurface,
        indicatorColor: c.primaryAccent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: c.onAccent, size: 23);
          }
          return IconThemeData(color: c.secondaryText, size: 23);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: c.primaryAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return TextStyle(
            color: c.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.secondarySurface,
        selectedItemColor: c.primaryAccent,
        unselectedItemColor: c.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.secondarySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? c.cardSurface
            : c.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.onAccent;
          }
          return c.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primaryAccent;
          }
          return c.borderLight;
        }),
      ),
    );
  }
}
