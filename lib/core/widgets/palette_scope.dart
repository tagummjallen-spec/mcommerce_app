import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';

/// Rebuilds [child] whenever the active palette (light/dark) changes.
///
/// The storefront reads its colours from the runtime `AppColors` tokens rather
/// than from an inherited [Theme]. Widgets whose `build` never touches `Theme`
/// would therefore keep the previous palette when the user flips the switch,
/// and `const` page widgets are reused by the navigator as-is.
///
/// Wrapping each route's page in a [PaletteScope] makes the dependency
/// explicit: the scope listens to [themeBrightnessProvider] and re-keys its
/// subtree, so the page (and everything it builds) is re-created with the
/// palette that the root widget already applied for this frame.
class PaletteScope extends ConsumerWidget {
  final Widget child;

  const PaletteScope({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(themeBrightnessProvider);
    return KeyedSubtree(key: ValueKey<Brightness>(brightness), child: child);
  }
}
