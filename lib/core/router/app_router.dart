import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/navigation/main_scaffold.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/products/screens/shop_screen.dart';
import '../../features/products/screens/product_details_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_confirmation_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/order_history_screen.dart';
import '../../features/profile/screens/order_details_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/support/screens/support_chat_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Shell with bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ShopScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:productId',
                    builder: (context, state) => ProductDetailsScreen(
                      productId: state.pathParameters['productId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrderHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: 'order-details/:orderId',
                        builder: (context, state) => OrderDetailsScreen(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Focused flow: hides bottom navigation
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportChatScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
