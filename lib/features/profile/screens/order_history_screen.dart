import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Processing':
      case 'Approved':
        return AppColors.info;
      case 'Shipped':
        return AppColors.primaryAccent;
      case 'Completed':
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.warning; // Pending
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final ordersAsync = ref.watch(customerOrdersProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: const BrandAppBar(
          showBack: true,
          showBag: false,
          title: 'ORDER HISTORY',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryAccent,
                  size: 44,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Login Required',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to view your orders.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('LOGIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(
        showBack: true,
        showBag: false,
        title: 'ORDER HISTORY',
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Failed to load orders.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(customerOrdersProvider),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.primaryAccent),
                ),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primaryAccent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No orders yet',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your completed checkouts will appear here.',
                      style: TextStyle(color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/shop'),
                      child: const Text('START SHOPPING'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryAccent,
            backgroundColor: AppColors.secondarySurface,
            onRefresh: () async => ref.invalidate(customerOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final dateStr = DateFormat('MMM d, yyyy • h:mm a')
                    .format(order.createdAt);

                return GestureDetector(
                  onTap: () =>
                      context.push('/profile/orders/order-details/${order.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(order.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(order.status)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(order.status),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.items
                                    .take(2)
                                    .map(
                                      (i) => '${i.quantity}× ${i.productName}',
                                    )
                                    .join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} • ₱${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Payment: ${order.paymentMethod} (Simulated)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.tertiaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'View details ›',
                              style: TextStyle(
                                color: AppColors.lightAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
