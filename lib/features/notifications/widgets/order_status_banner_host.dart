import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/order_status_provider.dart';

/// Shows a floating in-app alert whenever the live order stream observes an
/// admin-driven status change (for example Processing -> Shipped).
///
/// Mounted above the navigator so the alert is visible on every screen.
class OrderStatusBannerHost extends ConsumerStatefulWidget {
  final Widget child;

  const OrderStatusBannerHost({super.key, required this.child});

  @override
  ConsumerState<OrderStatusBannerHost> createState() =>
      _OrderStatusBannerHostState();
}

class _OrderStatusBannerHostState extends ConsumerState<OrderStatusBannerHost> {
  @override
  Widget build(BuildContext context) {
    ref.listen<OrderStatusUpdate?>(orderStatusUpdateProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showUpdate(context, next);
      });
    });

    return widget.child;
  }

  void _showUpdate(BuildContext context, OrderStatusUpdate update) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final accent = update.isCancelled
        ? AppColors.error
        : update.isCompleted
        ? AppColors.success
        : AppColors.primaryAccent;

    final icon = update.isCancelled
        ? Icons.cancel_outlined
        : update.isCompleted
        ? Icons.check_circle_outline
        : Icons.local_shipping_outlined;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.secondarySurface,
          elevation: 10,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          duration: const Duration(seconds: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.2),
          ),
          content: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order update',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      update.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: AppColors.primaryAccent,
            onPressed: () {
              ref
                  .read(appRouterProvider)
                  .push('/profile/orders/order-details/${update.orderId}');
            },
          ),
        ),
      );
  }
}
