import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  double _shippingFee(double subtotal) {
    if (subtotal <= 0) return 0;
    return subtotal >= AppConstants.freeShippingThreshold
        ? 0
        : AppConstants.standardShippingFee;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final subtotal = cart.subtotal;
    final shipping = _shippingFee(subtotal);
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: BrandAppBar(
        showBack: true,
        showBag: false,
        title: 'MY CART',
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, cartNotifier),
              child: Text(
                'Clear All',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
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
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primaryAccent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some gear and start your ascent.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () => context.go('/shop'),
                      child: const Text('BROWSE SHOP'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // ===== Select all bar =====
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 2, 20, 2),
                  child: Row(
                    children: [
                      Checkbox(
                        value: cart.allSelected,
                        onChanged: (value) =>
                            cartNotifier.setAllSelected(value ?? false),
                        activeColor: AppColors.primaryAccent,
                        checkColor: AppColors.onAccent,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: AppColors.secondaryText,
                          width: 1.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            cartNotifier.setAllSelected(!cart.allSelected),
                        child: Text(
                          'Select all',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${cart.selectedCount} of ${cart.items.length} selected',
                        style: TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // ===== Items list =====
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.selected
                                ? AppColors.primaryAccent.withValues(
                                    alpha: 0.45,
                                  )
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selection checkbox
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Checkbox(
                                value: item.selected,
                                onChanged: (_) =>
                                    cartNotifier.toggleSelected(item.id),
                                activeColor: AppColors.primaryAccent,
                                checkColor: AppColors.onAccent,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: AppColors.secondaryText,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            // Thumbnail
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: () {
                                final path = item.productImage.trim();
                                if (path.isEmpty) {
                                  return Center(
                                    child: Icon(
                                      Icons.sports_martial_arts,
                                      color: AppColors.tertiaryText,
                                      size: 28,
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
                                        errorBuilder: (_, _, _) => Center(
                                          child: Icon(
                                            Icons.sports_martial_arts,
                                            color: AppColors.tertiaryText,
                                            size: 28,
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
                                      color: AppColors.tertiaryText,
                                      size: 28,
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
                                        color: AppColors.tertiaryText,
                                        size: 28,
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
                                        color: AppColors.tertiaryText,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                }
                                return Center(
                                  child: Icon(
                                    Icons.sports_martial_arts,
                                    color: AppColors.tertiaryText,
                                    size: 28,
                                  ),
                                );
                              }(),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.selectedSize} · ${item.selectedColor}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₱${item.unitPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Quantity stepper
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _QtyBtn(
                                              icon: Icons.remove,
                                              onTap: () => cartNotifier
                                                  .decreaseQuantity(item.id),
                                            ),
                                            SizedBox(
                                              width: 32,
                                              child: Text(
                                                '${item.quantity}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColors.primaryText,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            _QtyBtn(
                                              icon: Icons.add,
                                              onTap:
                                                  item.quantity <
                                                      item.availableStock
                                                  ? () => cartNotifier
                                                        .increaseQuantity(
                                                          item.id,
                                                        )
                                                  : () =>
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Only ${item.availableStock} in stock.',
                                                            ),
                                                            backgroundColor:
                                                                AppColors
                                                                    .warning,
                                                          ),
                                                        ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Remove
                                      IconButton(
                                        onPressed: () =>
                                            cartNotifier.removeItem(item.id),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ===== Summary bar =====
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        _SummaryRow(
                          label:
                              'Subtotal (${cart.selectedCount} selected)',
                          value: subtotal,
                        ),
                        _SummaryRow(
                          label: 'Shipping (simulated)',
                          value: shipping,
                          valueColor: shipping == 0
                              ? AppColors.success
                              : AppColors.secondaryText,
                          trailing: shipping == 0 ? 'FREE' : null,
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '₱${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToCheckout(context, cart),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('PROCEED TO CHECKOUT'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/shop'),
                          child: Text(
                            'Continue Shopping',
                            style: TextStyle(
                              color: AppColors.lightAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _goToCheckout(BuildContext context, CartState cart) {
    if (!cart.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select at least one item to checkout.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    context.push('/checkout');
  }

  void _confirmClearAll(BuildContext context, CartNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        title: Text(
          'Clear cart?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Text(
          'This will remove all items from your cart.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 16, color: AppColors.primaryText),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? valueColor;
  final String? trailing;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

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
          Row(
            children: [
              if (trailing != null) ...[
                Text(
                  '$trailing  ',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              Text(
                '₱${value.toStringAsFixed(2)}',
                style: TextStyle(
                  color: valueColor ?? AppColors.primaryText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
