import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/wishlist_provider.dart';
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
  final PageController _pageController = PageController();

  int _currentImageIndex = 0;
  String? _selectedVariantId;
  int _quantity = 1;
  bool _addingToCart = false;
  bool _checkingReviewEligibility = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        actionTextColor: AppColors.onAccent,
        onViewCart: () => context.push('/cart'),
      ),
    );
  }

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

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(showBack: true),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => _ErrorState(
          message: 'Failed to load product.',
          onRetry: () => ref.invalidate(productProvider(widget.productId)),
        ),
        data: (product) {
          if (product == null) {
            return _ErrorState(
              message: 'Product not found.',
              onRetry: () => context.go('/shop'),
              actionLabel: 'Back to Shop',
              icon: Icons.search_off_rounded,
            );
          }

          _selectDefaultVariant(product);
          final selected = _selectedVariant(product);
          final isWishlisted = wishlist.contains(product.id);
          final maxQty = selected != null && selected.stock > 0
              ? (selected.stock < 10 ? selected.stock : 10)
              : 1;
          final stock = selected?.stock ?? product.totalStock;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _ImageGallery(
                        product: product,
                        controller: _pageController,
                        currentIndex: _currentImageIndex,
                        onPageChanged: (i) =>
                            setState(() => _currentImageIndex = i),
                      ),
                      Positioned(
                        top: 18,
                        right: 34,
                        child: _WishlistButton(
                          isActive: isWishlisted,
                          onTap: () => ref
                              .read(wishlistProvider.notifier)
                              .toggle(product.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ThumbnailGallery(
                    product: product,
                    currentIndex: _currentImageIndex,
                    onSelected: (i) {
                      setState(() => _currentImageIndex = i);
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 10),
                        _ReviewsSummary(productId: product.id),
                        const SizedBox(height: 16),
                        _PriceAndStock(price: product.price, stock: stock),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        const _SectionTitle('Product details'),
                        const SizedBox(height: 10),
                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : 'No description available for this product yet.',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            height: 1.65,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (product.variants.isNotEmpty) ...[
                          const _SectionTitle('Select variation'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: product.variants.map((v) {
                              final isSelected = v.id == _selectedVariantId;
                              final disabled = v.stock <= 0;
                              return _VariantChip(
                                variant: v,
                                selected: isSelected,
                                disabled: disabled,
                                onTap: disabled
                                    ? null
                                    : () => setState(() {
                                        _selectedVariantId = v.id;
                                        _quantity = 1;
                                      }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            const Expanded(
                              child: _SectionTitle('Quantity'),
                            ),
                            _QuantityStepper(
                              quantity: _quantity,
                              canDecrease: _quantity > 1,
                              canIncrease: selected != null &&
                                  selected.stock > 0 &&
                                  _quantity < maxQty,
                              onDecrease: () =>
                                  setState(() => _quantity--),
                              onIncrease: () =>
                                  setState(() => _quantity++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        const _SectionTitle('Reviews'),
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
                                      color: AppColors.onAccent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.rate_review_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              _checkingReviewEligibility
                                  ? 'Checking purchase...'
                                  : 'Write a review',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Only verified customers with a completed order can '
                          'review this product.',
                          style: TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 11.5,
                            height: 1.4,
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
                                    padding: EdgeInsets.symmetric(vertical: 8),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // ===== Sticky add to cart bar =====
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          final selected = _selectedVariant(product);
          final outOfStock = product.variants.isEmpty
              ? product.totalStock <= 0
              : product.variants.every((v) => v.stock <= 0);
          final effectiveStock = selected?.stock ?? product.totalStock;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(
              color: AppColors.secondarySurface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (outOfStock || _addingToCart || effectiveStock <= 0)
                          ? null
                          : () => _addToCart(product),
                      icon: _addingToCart
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onAccent,
                              ),
                            )
                          : const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(
                        outOfStock ? 'Out of stock' : 'Add to cart',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final ProductModel product;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.product,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.imageUrls;
    final count = images.isEmpty ? 1 : images.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (images.isEmpty)
                const ColoredBox(
                  color: AppColors.cardSurface,
                  child: Center(
                    child: Icon(
                      Icons.sports_martial_arts,
                      size: 72,
                      color: AppColors.tertiaryText,
                    ),
                  ),
                )
              else
                PageView.builder(
                  controller: controller,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, i) => AppImage(
                    source: images[i],
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.sports_martial_arts,
                    fallbackIconSize: 64,
                  ),
                ),
              // Fractional pagination indicator.
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailGallery extends StatelessWidget {
  final ProductModel product;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _ThumbnailGallery({
    required this.product,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.imageUrls;
    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _Thumb(
          selected: true,
          onTap: () {},
          child: const Icon(
            Icons.sports_martial_arts,
            size: 24,
            color: AppColors.tertiaryText,
          ),
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _Thumb(
          selected: i == currentIndex,
          onTap: () => onSelected(i),
          child: AppImage(
            source: images[i],
            fit: BoxFit.cover,
            fallbackIcon: Icons.broken_image_outlined,
            fallbackIconSize: 20,
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _Thumb({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 66,
        height: 66,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

class _ReviewsSummary extends ConsumerWidget {
  final String productId;

  const _ReviewsSummary({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(productRatingStatsProvider(productId));
    return Row(
      children: [
        RatingStars(rating: stats.average, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stats.count > 0
                ? '${stats.average.toStringAsFixed(1)} '
                      '(${stats.count} ${stats.count == 1 ? 'review' : 'reviews'})'
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
  }
}

class _PriceAndStock extends StatelessWidget {
  final double price;
  final int stock;

  const _PriceAndStock({required this.price, required this.stock});

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final color = inStock ? AppColors.success : AppColors.error;
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '₱${price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                inStock ? 'In stock - $stock left' : 'Out of stock',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _WishlistButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive ? 'Remove from wishlist' : 'Add to wishlist',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? AppColors.error.withValues(alpha: 0.08) : AppColors.secondarySurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryText.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isActive ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: isActive ? AppColors.error : AppColors.primaryText,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  final ProductVariant variant;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _VariantChip({
    required this.variant,
    required this.selected,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryAccent : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
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
              '${variant.size} · ${variant.color}',
              style: TextStyle(
                color: disabled
                    ? AppColors.tertiaryText
                    : selected
                    ? AppColors.onAccent
                    : AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
            if (disabled)
              const Text(
                'Sold out',
                style: TextStyle(color: AppColors.error, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: canDecrease ? onDecrease : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: canIncrease ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primaryText : AppColors.tertiaryText,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String actionLabel;
  final IconData icon;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.tertiaryText, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
