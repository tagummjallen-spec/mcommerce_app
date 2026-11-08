import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';

/// Post-checkout confirmation screen ("Order request received").
class CheckoutSuccessScreen extends ConsumerWidget {
  final String orderId;

  const CheckoutSuccessScreen({super.key, required this.orderId});

  String get _shortOrderId =>
      '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    final order = orderAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(showBack: false, showBag: false),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // ===== Status mark =====
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryAccent.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryAccent,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Order request received',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We have received your order request. Our team will confirm '
                      'availability and prepare your gear for delivery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== Order summary card =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: orderAsync.when(
                        loading: () => Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        error: (_, _) => _SummaryFallback(
                          shortOrderId: _shortOrderId,
                        ),
                        data: (order) {
                          if (order == null) {
                            return _SummaryFallback(
                              shortOrderId: _shortOrderId,
                            );
                          }
                          return _OrderSummary(order: order);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Cash reminder banner =====
                    if (order != null) _CashBanner(order: order),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ===== Bottom actions =====
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go(
                          '/profile/orders/order-details/$orderId',
                        ),
                        child: const Text('View order details'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: order == null
                            ? null
                            : () => _showReceipt(context, order),
                        child: const Text('Download receipt'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceipt(BuildContext context, OrderModel order) {
    final receipt = _buildReceiptText(order);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receipt'),
        content: SingleChildScrollView(
          child: SelectableText(
            receipt,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.primaryText,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: receipt));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Receipt copied to clipboard.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _buildReceiptText(OrderModel order) {
    final buffer = StringBuffer()
      ..writeln('ASCENDED ATHLETICS')
      ..writeln('Order receipt (simulated)')
      ..writeln('------------------------------')
      ..writeln('Order ID : $orderId')
      ..writeln('Items    : ${order.itemCount}')
      ..writeln('Subtotal : PHP ${order.subtotal.toStringAsFixed(2)}')
      ..writeln('Shipping : PHP ${order.shippingFee.toStringAsFixed(2)}')
      ..writeln('Total    : PHP ${order.total.toStringAsFixed(2)}')
      ..writeln('Payment  : ${order.paymentMethod} (${order.paymentStatus})')
      ..writeln('------------------------------')
      ..writeln('No real payment was processed.');
    return buffer.toString();
  }
}

class _OrderSummary extends StatelessWidget {
  final OrderModel order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId =
        '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ORDER SUMMARY',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'REQUESTED',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SummaryRow(label: 'Order ID', value: shortId),
        _SummaryRow(label: 'Items', value: '${order.itemCount}'),
        const Divider(height: 22),
        _SummaryRow(
          label: 'Subtotal',
          value: '₱${order.subtotal.toStringAsFixed(2)}',
        ),
        _SummaryRow(
          label: 'Shipping fee',
          value: order.shippingFee == 0
              ? 'FREE'
              : '₱${order.shippingFee.toStringAsFixed(2)}',
          valueColor: order.shippingFee == 0
              ? AppColors.success
              : AppColors.primaryText,
        ),
        const Divider(height: 22),
        _SummaryRow(
          label: 'Total amount',
          value: '₱${order.total.toStringAsFixed(2)}',
          emphasized: true,
        ),
        const SizedBox(height: 6),
        _SummaryRow(label: 'Payment method', value: order.paymentMethod),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Payment status',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ),
              _PaymentStatusBadge(order: order),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryFallback extends StatelessWidget {
  final String shortOrderId;

  const _SummaryFallback({required this.shortOrderId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORDER SUMMARY',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        _SummaryRow(label: 'Order ID', value: shortOrderId),
        const _SummaryRow(label: 'Status', value: 'Request received'),
        const SizedBox(height: 4),
        Text(
          'Full details will appear once the order finishes syncing.',
          style: TextStyle(color: AppColors.tertiaryText, fontSize: 12),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: emphasized
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontSize: emphasized ? 14 : 13,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasized ? 17 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final OrderModel order;

  const _PaymentStatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final color = isPaid ? AppColors.success : AppColors.error;
    final label = isPaid
        ? 'Paid'
        : 'Unpaid (${order.paymentMethod})';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CashBanner extends StatelessWidget {
  final OrderModel order;

  const _CashBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final color = isPaid ? AppColors.success : AppColors.warning;
    final IconData icon = isPaid
        ? Icons.verified_rounded
        : Icons.payments_outlined;
    final String message = isPaid
        ? 'Payment received. No cash is needed when your order arrives.'
        : 'Please prepare exactly ₱${order.total.toStringAsFixed(2)} in cash for the rider. '
              'Having the exact amount ready helps keep the delivery quick and contactless.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Payment confirmed' : 'Cash on delivery reminder',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
