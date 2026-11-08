import 'package:flutter/material.dart';

/// Minimalist cream / dark-green palette used across the storefront.
class AppColors {
  // Surfaces
  static const Color primaryBackground = Color(0xFFFAF7F0); // Cream / off-white
  static const Color secondarySurface = Color(0xFFFFFFFF); // Card white
  static const Color cardSurface = Color(0xFFF2EDE2); // Soft sand panel

  // Interactive / brand greens
  static const Color primaryAccent = Color(0xFF1F4D3A); // Deep forest green
  static const Color deepAccent = Color(0xFF163A2B); // Darkest green
  static const Color lightAccent = Color(0xFF3E7A5E); // Mid green accent

  // Text
  static const Color primaryText = Color(0xFF1C2A22); // Near-black green
  static const Color secondaryText = Color(0xFF66756B); // Muted green-grey
  static const Color tertiaryText = Color(0xFF98A49B); // Soft grey-green
  static const Color onAccent = Color(0xFFFFFFFF); // Text on dark green

  // Borders & dividers
  static const Color border = Color(0xFFE7E1D5); // Warm hairline
  static const Color borderLight = Color(0xFFD4CBBB); // Stronger warm hairline

  // Feedback & status
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFC8842A);
  static const Color error = Color(0xFFBE3A2B);
  static const Color info = Color(0xFF3A6EA5);

  // Extras used by the new Shopee-like surfaces.
  static const Color softGreen = Color(0xFFEAF1EC); // Tinted green panel
  static const Color softSand = Color(0xFFF6F0E4); // Tinted sand panel
}
