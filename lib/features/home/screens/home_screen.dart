import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/support_chat_provider.dart';
import '../../products/widgets/product_card.dart';
import '../widgets/promo_banner.dart';
import '../widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final isGuest = ref.watch(isGuestProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final supportUnread = ref.watch(supportUnreadByCustomerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryAccent,
          backgroundColor: AppColors.secondarySurface,
          onRefresh: () async => ref.invalidate(productsProvider),
          child: CustomScrollView(
            slivers: [
              // ===== Brand header =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primaryAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppConstants.appName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              isGuest ? 'Browsing as Guest' : 'Signed in',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.tertiaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.search,
                            onTap: () => context.go('/shop'),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.support_agent_outlined,
                            badgeCount: supportUnread,
                            onTap: () => context.push('/support'),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.notifications_outlined,
                            badgeCount: unreadNotifications,
                            onTap: () => context.go('/profile/notifications'),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.shopping_bag_outlined,
                            badgeCount: cartCount,
                            onTap: () => context.go('/cart'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ===== Promotional banner =====
              const SliverToBoxAdapter(child: PromoBanner()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ===== Shop by discipline =====
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Shop by Discipline',
                  actionLabel: 'View All',
                  onAction: () => context.go('/shop'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount:
                        AppConstants.disciplines.length - 1, // skip 'All'
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final discipline = AppConstants.disciplines[index + 1];
                      return CategoryTile(
                        label: discipline,
                        icon: disciplineIcon(discipline),
                        onTap: () {
                          ref
                              .read(shopFilterProvider.notifier)
                              .setDiscipline(discipline);
                          context.go('/shop');
                        },
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ===== Featured products =====
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Featured',
                  actionLabel: 'Shop All',
                  onAction: () => context.go('/shop'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: productsAsync.when(
                  loading: () => const _ProductRowSkeleton(),
                  error: (e, _) => _ErrorState(
                    message: 'Could not load products.',
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                  data: (products) {
                    final featured = products.take(6).toList();
                    if (featured.isEmpty) {
                      return const _EmptyState(
                        message: 'No products available yet.',
                      );
                    }
                    return SizedBox(
                      height: 265,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            ProductCard(product: featured[index]),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ===== New arrivals =====
              SliverToBoxAdapter(child: SectionHeader(title: 'New Arrivals')),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: productsAsync.when(
                  loading: () => const _ProductRowSkeleton(),
                  error: (e, _) => _ErrorState(
                    message: 'Could not load new arrivals.',
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                  data: (products) {
                    // products are ordered by createdAt desc in the service
                    final arrivals = products.take(8).toList();
                    if (arrivals.isEmpty) {
                      return const _EmptyState(
                        message: 'Nothing new just yet.',
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: arrivals.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                        itemBuilder: (context, index) => ProductCard(
                          product: arrivals[index],
                          width: double.infinity,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support'),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: Badge(
          isLabelVisible: supportUnread > 0,
          label: Text('$supportUnread'),
          backgroundColor: AppColors.error,
          child: const Icon(Icons.chat_bubble_outline),
        ),
        label: const Text('Support'),
      ),
    );
  }
}

class _ProductRowSkeleton extends StatelessWidget {
  const _ProductRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 265,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 180,
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text('$badgeCount'),
          backgroundColor: AppColors.primaryAccent,
          child: Icon(icon, color: AppColors.primaryText, size: 20),
        ),
      ),
    );
  }
}
