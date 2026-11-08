import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/review_provider.dart';
import '../../reviews/widgets/review_flow.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isCancelling = false;

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
        return AppColors.warning;
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        title: Text(
          'Cancel this order?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'The order status will change to Cancelled. This cannot be undone.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Order',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(orderServiceProvider).cancelOrder(order.id);
      ref.invalidate(orderProvider(widget.orderId));
      ref.invalidate(customerOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(
        showBack: true,
        showBag: false,
        title: 'ORDER DETAILS',
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 42),
              const SizedBox(height: 12),
              Text(
                'Failed to load order: $e',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(orderProvider(widget.orderId)),
                child: Text(
                  'Retry',
                  style: TextStyle(color: AppColors.primaryAccent),
                ),
              ),
            ],
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text(
                'Order not found.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            );
          }

          final statusLower = order.status.trim().toLowerCase();
          final isCompleted =
              statusLower == 'completed' || statusLower == 'delivered';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Status header =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(16),
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
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
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
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('MMMM d, yyyy • h:mm a')
                            .format(order.createdAt),
                        style: TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Payment: ${order.paymentMethod} (Simulated)',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Items =====
                Text(
                  'ITEMS (${order.itemCount})',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: order.items.map((item) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: () {
                                    final path = item.productImage.trim();
                                    if (path.isEmpty) {
                                      return Center(
                                        child: Icon(
                                          Icons.sports_martial_arts,
                                          size: 20,
                                          color: AppColors.tertiaryText,
                                        ),
                                      );
                                    }
                                    if (path.startsWith('data:image/')) {
                                      try {
                                        final commaIndex = path.indexOf(',');
                                        if (commaIndex >= 0 &&
                                            commaIndex < path.length - 1) {
                                          return Image.memory(
                                            base64Decode(
                                              path.substring(commaIndex + 1),
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.sports_martial_arts,
                                                    size: 20,
                                                    color:
                                                        AppColors.tertiaryText,
                                                  ),
                                                ),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('DATA URL IMAGE ERROR: $e');
                                      }
                                      return Center(
                                        child: Icon(
                                          Icons.sports_martial_arts,
                                          size: 20,
                                          color: AppColors.tertiaryText,
                                        ),
                                      );
                                    }
                                    if (path.startsWith('assets/')) {
                                      return Image.asset(
                                        path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Center(
                                          child: Icon(
                                            Icons.sports_martial_arts,
                                            size: 20,
                                            color: AppColors.tertiaryText,
                                          ),
                                        ),
                                      );
                                    }
                                    if (path.startsWith('http')) {
                                      return Image.network(
                                        path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Center(
                                          child: Icon(
                                            Icons.sports_martial_arts,
                                            size: 20,
                                            color: AppColors.tertiaryText,
                                          ),
                                        ),
                                      );
                                    }
                                    return Center(
                                      child: Icon(
                                        Icons.sports_martial_arts,
                                        size: 20,
                                        color: AppColors.tertiaryText,
                                      ),
                                    );
                                  }(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.selectedSize} · ${item.selectedColor}  •  Qty ${item.quantity}',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₱${item.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted && item.productId.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _OrderItemReviewButton(
                                    productId: item.productId,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Totals =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _Line(
                        label: 'Subtotal',
                        value: '₱${order.subtotal.toStringAsFixed(2)}',
                      ),
                      _Line(
                        label: 'Shipping Fee',
                        value: order.shippingFee == 0
                            ? 'FREE'
                            : '₱${order.shippingFee.toStringAsFixed(2)}',
                        valueColor: order.shippingFee == 0
                            ? AppColors.success
                            : AppColors.secondaryText,
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '₱${order.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Shipping address =====
                Text(
                  'SHIPPING ADDRESS',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shippingAddress.fullName,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress.fullAddress,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.shippingAddress.phone} • ${order.shippingAddress.email}',
                        style: TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ===== Cancel action (Pending only) =====
                if (order.isEligibleForCancellation)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCancelling
                          ? null
                          : () => _cancelOrder(order),
                      icon: _isCancelling
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        _isCancelling ? 'CANCELLING…' : 'CANCEL ORDER',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error,
                          width: 1.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      'This order is ${order.status.toLowerCase()} and can no longer be cancelled.',
                      style: TextStyle(
                        color: AppColors.tertiaryText,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shopee-style review action shown beside each item of a completed order.
/// Switches to "VIEW REVIEW" when the customer already reviewed the product.
class _OrderItemReviewButton extends ConsumerWidget {
  final String productId;

  const _OrderItemReviewButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(userReviewForProductProvider(productId));
    final hasReview = reviewAsync.valueOrNull != null;

    return OutlinedButton.icon(
      onPressed: reviewAsync.isLoading
          ? null
          : () => openOrderReviewFlow(
              context: context,
              ref: ref,
              productId: productId,
            ),
      icon: Icon(
        hasReview ? Icons.visibility_outlined : Icons.rate_review_outlined,
        size: 15,
      ),
      label: Text(
        hasReview ? 'VIEW REVIEW' : 'RATE PRODUCT',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        side: BorderSide(
          color: AppColors.primaryAccent.withValues(alpha: 0.55),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Line({required this.label, required this.value, this.valueColor});

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
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
