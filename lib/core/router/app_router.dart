import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../widgets/palette_scope.dart';
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
import '../../features/checkout/screens/checkout_success_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/order_history_screen.dart';
import '../../features/profile/screens/order_details_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/support/screens/support_chat_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Wraps a page so its content is rebuilt whenever the active palette changes.
///
/// Screens read the runtime `AppColors` global rather than an inherited
/// [Theme], so Flutter would otherwise reuse their (often `const`) widgets
/// unchanged when the user flips the light/dark switch. [PaletteScope]
/// subscribes to the Riverpod theme provider and re-creates the page subtree
/// with the palette the root widget applied for this frame.
Widget _paletteScoped(Widget child) => PaletteScope(child: child);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => _paletteScoped(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => _paletteScoped(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => _paletteScoped(const RegisterScreen()),
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
                builder: (context, state) => _paletteScoped(const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => _paletteScoped(const ShopScreen()),
                routes: [
                  GoRoute(
                    path: 'product/:productId',
                    builder: (context, state) => _paletteScoped(
                      ProductDetailsScreen(
                        productId: state.pathParameters['productId']!,
                      ),
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
                builder: (context, state) =>
                    _paletteScoped(const WishlistScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    _paletteScoped(const ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) =>
                        _paletteScoped(const OrderHistoryScreen()),
                    routes: [
                      GoRoute(
                        path: 'order-details/:orderId',
                        builder: (context, state) => _paletteScoped(
                          OrderDetailsScreen(
                            orderId: state.pathParameters['orderId']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        _paletteScoped(const EditProfileScreen()),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        _paletteScoped(const NotificationsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Focused flow: hides bottom navigation
      GoRoute(
        path: '/cart',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => _paletteScoped(const CartScreen()),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => _paletteScoped(const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => _paletteScoped(
          CheckoutSuccessScreen(orderId: state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => _paletteScoped(const SupportChatScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
