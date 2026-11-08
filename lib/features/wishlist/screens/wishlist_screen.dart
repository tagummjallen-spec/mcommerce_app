import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../products/widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final wishlistAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: const Text('WISHLIST')),
      body: isGuest
          ? _LoginGate(
              message:
                  'Sign in to save your favorite gear and access your wishlist.',
              onLogin: () => context.go('/login'),
            )
          : wishlistAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryAccent),
              ),
              error: (e, _) => const Center(
                child: Text('Failed to load wishlist.',
                    style: TextStyle(color: AppColors.secondaryText)),
              ),
              data: (products) {
                if (products.isEmpty) {
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
                              Icons.favorite_outline,
                              color: AppColors.primaryAccent,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your wishlist is empty',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the heart on any product to save it here.',
                            style: TextStyle(color: AppColors.secondaryText),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: () => context.go('/shop'),
                            child: const Text('BROWSE SHOP'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Stack(
                      children: [
                        ProductCard(product: product, width: double.infinity),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => ref
                                .read(wishlistProvider.notifier)
                                .remove(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackground
                                    .withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: AppColors.error,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;

  const _LoginGate({required this.message, required this.onLogin});

  @override
  Widget build(BuildContext context) {
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
                Icons.lock_outline,
                color: AppColors.primaryAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Login Required',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('LOGIN'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text(
                'Create an account',
                style: TextStyle(color: AppColors.lightAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
