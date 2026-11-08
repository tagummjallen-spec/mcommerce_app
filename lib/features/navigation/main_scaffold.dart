import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/cart_provider.dart';

/// Wraps the five primary tabs: Home, Shop, Wishlist, Cart, Profile.
class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondarySurface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.secondarySurface,
          indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.18),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primaryAccent),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront, color: AppColors.primaryAccent),
              label: 'Shop',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite, color: AppColors.primaryAccent),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: AppColors.primaryAccent,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: AppColors.primaryAccent,
                child: const Icon(Icons.shopping_bag, color: AppColors.primaryAccent),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primaryAccent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
