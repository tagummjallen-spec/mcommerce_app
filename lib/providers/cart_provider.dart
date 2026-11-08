import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import 'auth_provider.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

/// Cart state: a list of CartItemModel shared by guest and logged-in users.
class CartState {
  final List<CartItemModel> items;
  const CartState({this.items = const []});

  double get subtotal => items.fold(0.0, (acc, item) => acc + item.totalPrice);
  int get totalQuantity => items.fold(0, (acc, item) => acc + item.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  CartNotifier(this.ref) : super(const CartState()) {
    _loadForCurrentUser();
  }

  Future<void> _loadForCurrentUser() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      final items = await ref.read(cartServiceProvider).loadCart(user.uid);
      state = CartState(items: items);
    }
  }

  /// Called after login/registration: merges the Firestore cart with the
  /// local (guest) cart so nothing the user added before signing in is lost.
  Future<void> reloadForUser() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      final remote = await ref.read(cartServiceProvider).loadCart(user.uid);
      if (state.items.isEmpty) {
        state = CartState(items: remote);
        return;
      }
      final merged = [...state.items];
      for (final r in remote) {
        final index = merged.indexWhere((i) => i.id == r.id);
        if (index >= 0) {
          final local = merged[index];
          final qty =
              (local.quantity + r.quantity).clamp(1, local.availableStock);
          merged[index] = local.copyWith(quantity: qty);
        } else {
          merged.add(r);
        }
      }
      state = CartState(items: merged);
      await _persist();
    } catch (_) {
      // Keep the local cart if the remote merge fails.
    }
  }

  /// Reset to an empty cart (guest entry or logout).
  void resetToEmpty() => state = const CartState();

  String _cartItemId(String productId, String variantId) => '${productId}_$variantId';

  void addItem({
    required ProductModel product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    final id = _cartItemId(product.id, variant.id);
    final existingIndex =
        state.items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      final current = state.items[existingIndex];
      final newQty = (current.quantity + quantity).clamp(1, variant.stock);
      final updated = current.copyWith(quantity: newQty);
      final items = [...state.items];
      items[existingIndex] = updated;
      state = CartState(items: items);
    } else {
      final newItem = CartItemModel(
        id: id,
        productId: product.id,
        productName: product.name,
        productImage: product.images.isNotEmpty ? product.images.first : '',
        unitPrice: product.price,
        selectedSize: variant.size,
        selectedColor: variant.color,
        variantId: variant.id,
        quantity: quantity.clamp(1, variant.stock),
        availableStock: variant.stock,
      );
      state = CartState(items: [...state.items, newItem]);
    }
    _persist();
  }

  void increaseQuantity(String itemId) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.id == itemId);
    if (index < 0) return;
    final item = items[index];
    if (item.quantity + 1 > item.availableStock) return;
    items[index] = item.copyWith(quantity: item.quantity + 1);
    state = CartState(items: items);
    _persist();
  }

  void decreaseQuantity(String itemId) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.id == itemId);
    if (index < 0) return;
    final item = items[index];
    if (item.quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(quantity: item.quantity - 1);
    }
    state = CartState(items: items);
    _persist();
  }

  void removeItem(String itemId) {
    state = CartState(items: [...state.items.where((i) => i.id != itemId)]);
    _persist();
  }

  void clear() {
    state = const CartState();
    _persist();
  }

  /// Remove only the purchased items after a successful order.
  void clearPurchasedItems(List<String> purchasedItemIds) {
    state = CartState(
      items: [...state.items.where((i) => !purchasedItemIds.contains(i.id))],
    );
    _persist();
  }

  Future<void> _persist() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      try {
        await ref.read(cartServiceProvider).saveCart(user.uid, state.items);
      } catch (_) {
        // Local state remains the source of truth if sync fails.
      }
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalQuantity;
});
