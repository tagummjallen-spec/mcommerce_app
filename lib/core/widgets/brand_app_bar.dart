import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../../providers/cart_provider.dart';

/// Store-wide app bar: optional back button, centered brand wordmark/logo and
/// a shopping bag shortcut with a live cart badge.
class BrandAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBack;
  final bool showBag;
  final VoidCallback? onBack;
  final String? title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  const BrandAppBar({
    super.key,
    this.showBack = false,
    this.showBag = true,
    this.onBack,
    this.title,
    this.actions = const [],
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      toolbarHeight: toolbarHeight,
      backgroundColor: AppColors.primaryBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: showBack
          ? IconButton(
              tooltip: 'Back',
              onPressed: () => _handleBack(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            )
          : null,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.onAccent,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title ?? AppConstants.appName.toUpperCase(),
              maxLines: 1,
            ),
          ],
        ),
      ),
      actions: [
        ...actions,
        if (showBag) _BagButton(count: ref.watch(cartItemCountProvider)),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }
}

class _BagButton extends StatelessWidget {
  final int count;

  const _BagButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Shopping bag',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        child: const Icon(Icons.shopping_bag_outlined, size: 23),
      ),
    );
  }
}
