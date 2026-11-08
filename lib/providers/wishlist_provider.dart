import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import 'product_provider.dart';

/// Wishlist is stored locally in memory and persisted to
/// wishlists/{uid}/items for authenticated users via Firestore in a
/// production build; this implementation keeps a simple in-memory list
/// shared by guest and signed-in users for the academic demo.
final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, List<String>>((ref) {
  return WishlistNotifier();
});

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier() : super(const []);

  bool contains(String productId) => state.contains(productId);

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
  }

  void remove(String productId) {
    state = state.where((id) => id != productId).toList();
  }

  void clear() => state = const [];
}

/// Full product objects for the ids in the wishlist.
final wishlistProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final ids = ref.watch(wishlistProvider);
  final productsAsync = ref.watch(productsProvider);

  return productsAsync.whenData(
    (products) => products.where((p) => ids.contains(p.id)).toList(),
  );
});
