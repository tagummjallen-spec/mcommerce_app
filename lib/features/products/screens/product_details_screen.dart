import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/review_provider.dart';
import '../../reviews/widgets/rating_star.dart';
import '../../reviews/widgets/review_card.dart';
import '../../reviews/widgets/review_flow.dart';
import '../widgets/cart_notification.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  String? _selectedVariantId;
  int _quantity = 1;
  bool _addingToCart = false;
  bool _checkingReviewEligibility = false;

  void _selectDefaultVariant(ProductModel product) {
    if (_selectedVariantId != null) return;
    final inStock = product.variants.where((v) => v.stock > 0).toList();
    if (inStock.isNotEmpty) {
      _selectedVariantId = inStock.first.id;
    } else if (product.variants.isNotEmpty) {
      _selectedVariantId = product.variants.first.id;
    }
  }

  ProductVariant? _selectedVariant(ProductModel product) {
    try {
      return product.variants.firstWhere((v) => v.id == _selectedVariantId);
    } catch (_) {
      return product.variants.isNotEmpty ? product.variants.first : null;
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    final variant = _selectedVariant(product);
    if (variant == null) {
      _showSnack('No variation available for this product.', AppColors.error);
      return;
    }
    if (variant.stock <= 0) {
      _showSnack('This variation is out of stock.', AppColors.error);
      return;
    }
    if (_quantity > variant.stock) {
      _showSnack('Only ${variant.stock} left in stock.', AppColors.warning);
      return;
    }

    setState(() => _addingToCart = true);
    await Future.delayed(const Duration(milliseconds: 250)); // UI feedback
    ref
        .read(cartProvider.notifier)
        .addItem(product: product, variant: variant, quantity: _quantity);
    if (!mounted) return;
    setState(() => _addingToCart = false);
    _showSnack(
      '${product.name} (${variant.size} / ${variant.color}) added to cart!',
      AppColors.success,
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      buildProductNotificationSnackBar(
        message: message,
        backgroundColor: color,
        actionTextColor: AppColors.primaryText,
        onViewCart: () => context.go('/cart'),
      ),
    );
  }

  /// Opens the review form only after confirming the signed-in customer has a
  /// completed/delivered order containing this product. Otherwise shows the
  /// verified-reviews gate dialog.
  Future<void> _openReviewForm(ProductModel product) async {
    setState(() => _checkingReviewEligibility = true);
    try {
      await openVerifiedReviewFlow(
        context: context,
        ref: ref,
        productId: product.id,
      );
    } finally {
      if (mounted) setState(() => _checkingReviewEligibility = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final wishlist = ref.watch(wishlistProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Failed to load product.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productProvider(widget.productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    color: AppColors.tertiaryText,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Product not found.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => context.go('/shop'),
                    child: const Text('Back to Shop'),
                  ),
                ],
              ),
            );
          }

          _selectDefaultVariant(product);
          final selected = _selectedVariant(product);
          final isWishlisted = wishlist.contains(product.id);
          final maxQty = selected != null && selected.stock > 0
              ? (selected.stock < 10 ? selected.stock : 10)
              : 1;

          return SafeArea(
            child: Column(
              children: [
                // ===== Top bar =====
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/shop'),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: isWishlisted ? AppColors.error : null,
                            onTap: () => ref
                                .read(wishlistProvider.notifier)
                                .toggle(product.id),
                          ),
                          const SizedBox(width: 8),
                          _CircleIconButton(
                            icon: Icons.shopping_bag_outlined,
                            badge: cartCount,
                            onTap: () => context.go('/cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== Image gallery =====
                        Container(
                          height: 320,
                          margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: product.images.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.sports_martial_arts,
                                    size: 64,
                                    color: AppColors.tertiaryText,
                                  ),
                                )
                              : Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: product.images.length,
                                      onPageChanged: (i) => setState(
                                        () => _currentImageIndex = i,
                                      ),
                                      itemBuilder: (context, i) {
                                        final raw = product.images[i];
                                        final path = raw.trim();
                                        if (path.startsWith('data:image/')) {
                                          try {
                                            final commaIndex = path.indexOf(
                                              ',',
                                            );
                                            if (commaIndex >= 0 &&
                                                commaIndex < path.length - 1) {
                                              return Image.memory(
                                                base64Decode(
                                                  path.substring(
                                                    commaIndex + 1,
                                                  ),
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: AppColors
                                                            .tertiaryText,
                                                        size: 40,
                                                      ),
                                                    ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint(
                                              'DATA URL IMAGE ERROR: $e',
                                            );
                                          }
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: AppColors.tertiaryText,
                                              size: 40,
                                            ),
                                          );
                                        }
                                        if (path.startsWith('assets/')) {
                                          return Image.asset(
                                            path,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: AppColors
                                                            .tertiaryText,
                                                        size: 40,
                                                      ),
                                                    ),
                                          );
                                        }
                                        if (path.startsWith('http')) {
                                          return Image.network(
                                            path,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: AppColors
                                                              .primaryAccent,
                                                        ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: AppColors
                                                            .tertiaryText,
                                                        size: 40,
                                                      ),
                                                    ),
                                          );
                                        }
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: AppColors.tertiaryText,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                    if (product.images.length > 1)
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            product.images.length,
                                            (i) => AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                  ),
                                              width: _currentImageIndex == i
                                                  ? 20
                                                  : 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: _currentImageIndex == i
                                                    ? AppColors.primaryAccent
                                                    : AppColors.borderLight,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 20),

                        // ===== Name / price / disciplines =====
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '₱${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ...product.disciplines.map(
                                    (d) => _Tag(label: d, isAccent: true),
                                  ),
                                  _Tag(
                                    label: product.categoryId,
                                    isAccent: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Rating summary
                              Consumer(
                                builder: (context, ref, _) {
                                  final stats = ref.watch(
                                    productRatingStatsProvider(product.id),
                                  );
                                  return Row(
                                    children: [
                                      RatingStars(rating: stats.average),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stats.count > 0
                                              ? '${stats.average.toStringAsFixed(1)} (${stats.count} ${stats.count == 1 ? 'review' : 'reviews'})'
                                              : 'No reviews yet',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Stock availability
                              if (selected != null)
                                Row(
                                  children: [
                                    Icon(
                                      selected.stock > 0
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      size: 16,
                                      color: selected.stock > 0
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        selected.stock > 0
                                            ? 'In Stock (${selected.stock} left)'
                                            : 'Out of Stock',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selected.stock > 0
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Description
                              const Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description.isNotEmpty
                                    ? product.description
                                    : 'No description available.',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  height: 1.55,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ===== Variations =====
                              if (product.variants.isNotEmpty) ...[
                                const Text(
                                  'SELECT VARIATION',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: product.variants.map((v) {
                                    final isSelected =
                                        v.id == _selectedVariantId;
                                    final disabled = v.stock <= 0;
                                    return GestureDetector(
                                      onTap: disabled
                                          ? null
                                          : () => setState(() {
                                              _selectedVariantId = v.id;
                                              _quantity = 1;
                                            }),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryAccent
                                              : AppColors.secondarySurface,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryAccent
                                                : disabled
                                                ? AppColors.border
                                                : AppColors.borderLight,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${v.size} · ${v.color}',
                                              style: TextStyle(
                                                color: disabled
                                                    ? AppColors.tertiaryText
                                                    : isSelected
                                                    ? AppColors.primaryText
                                                    : AppColors.secondaryText,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                decoration: disabled
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (disabled)
                                              const Text(
                                                'Sold out',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ===== Quantity =====
                              Row(
                                children: [
                                  const Text(
                                    'Quantity',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '$_quantity',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onTap:
                                        (selected == null || _quantity < maxQty)
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // ===== Reviews =====
                              const Text(
                                'REVIEWS',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _checkingReviewEligibility
                                      ? null
                                      : () => _openReviewForm(product),
                                  icon: _checkingReviewEligibility
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.rate_review_outlined,
                                          size: 18,
                                        ),
                                  label: Text(
                                    _checkingReviewEligibility
                                        ? 'CHECKING PURCHASE...'
                                        : 'WRITE A REVIEW',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Only verified customers with a completed order '
                                'can review this product.',
                                style: TextStyle(
                                  color: AppColors.tertiaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Consumer(
                                builder: (context, ref, _) {
                                  final reviewsAsync = ref.watch(
                                    productReviewsProvider(product.id),
                                  );
                                  return reviewsAsync.when(
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryAccent,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    error: (e, _) => Text(
                                      'Failed to load reviews: $e',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    data: (reviews) {
                                      if (reviews.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            'No reviews yet. Be the first to review!',
                                            style: TextStyle(
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        );
                                      }
                                      return Column(
                                        children: reviews
                                            .map((r) => ReviewCard(review: r))
                                            .toList(),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // ===== Sticky Add to Cart bar =====
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          final outOfStock = product.variants.every((v) => v.stock <= 0);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: AppColors.secondarySurface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '₱${(product.price * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (outOfStock || _addingToCart)
                        ? null
                        : () => _addToCart(product),
                    icon: _addingToCart
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryText,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: Text(
                      outOfStock ? 'OUT OF STOCK' : 'ADD TO CART',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: outOfStock
                          ? AppColors.borderLight
                          : AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final int badge;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          backgroundColor: AppColors.primaryAccent,
          child: Icon(icon, size: 22, color: color ?? AppColors.primaryText),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.cardSurface : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.borderLight : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primaryText : AppColors.tertiaryText,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isAccent;

  const _Tag({required this.label, required this.isAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.primaryAccent.withValues(alpha: 0.14)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccent
              ? AppColors.primaryAccent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isAccent ? AppColors.lightAccent : AppColors.secondaryText,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
