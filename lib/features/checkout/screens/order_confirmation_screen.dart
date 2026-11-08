import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/order_provider.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Success mark
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'ORDER PLACED!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your order has been recorded and stock has been reserved.\nTrack its progress in your order history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Order id card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: orderAsync.when(
                          loading: () => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                          error: (e, _) => Column(
                            children: [
                              const Text(
                                'Order reference',
                                style: TextStyle(
                                  color: AppColors.tertiaryText,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '#$orderId',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          data: (order) {
                            if (order == null) {
                              return Text(
                                '#$orderId',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return Column(
                              children: [
                                const Text(
                                  'Order reference',
                                  style: TextStyle(
                                    color: AppColors.tertiaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 14),
                                _InfoRow(
                                  label: 'Status',
                                  value: order.status,
                                  valueColor: AppColors.warning,
                                ),
                                _InfoRow(
                                  label: 'Payment',
                                  value: '${order.paymentMethod} (Simulated)',
                                ),
                                _InfoRow(
                                  label: 'Total',
                                  value: '₱${order.total.toStringAsFixed(2)}',
                                  valueColor: AppColors.primaryAccent,
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const Spacer(),

                      // Actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go(
                            '/profile/orders/order-details/$orderId',
                          ),
                          child: const Text('VIEW ORDER DETAILS'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/shop'),
                          child: const Text('CONTINUE SHOPPING'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
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
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
