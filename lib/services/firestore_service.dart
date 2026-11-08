import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';

/// Firestore data access for the product catalog.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get productsRef => _firestore.collection('products');
  CollectionReference get categoriesRef => _firestore.collection('categories');
  CollectionReference get ordersRef => _firestore.collection('orders');
  CollectionReference get usersRef => _firestore.collection('users');

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final snapshot = await productsRef.get();

      final products = <ProductModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final product = ProductModel.fromMap(data, doc.id);
          if (product.isActive) {
            products.add(product);
          }
        } catch (e, st) {
          debugPrint('Failed to parse product ${doc.id}: $e');
          debugPrint(st.toString());
          continue;
        }
      }
      return products;
    } catch (e, st) {
      debugPrint('PRODUCTS PROVIDER ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<ProductModel?> fetchProduct(String id) async {
    try {
      final doc = await productsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      return ProductModel.fromMap(data, doc.id);
    } catch (e, st) {
      debugPrint('Failed to fetch/parse product $id: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<List<ProductModel>> fetchProductsByDiscipline(
    String discipline,
  ) async {
    if (discipline == 'All') return fetchProducts();
    final snapshot = await productsRef
        .where('disciplines', arrayContains: discipline)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProductModel.fromMap(data, doc.id);
        })
        .where((p) => p.isActive)
        .toList();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

/// All active products (fetched once, cached by Riverpod)
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(firestoreServiceProvider).fetchProducts();
});

/// Single product by id
final productProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  String id,
) async {
  return ref.watch(firestoreServiceProvider).fetchProduct(id);
});

/// Filter state for the Shop screen
class ShopFilterState {
  final String searchQuery;
  final String discipline;
  final String productType;
  final String sortBy; // 'newest' | 'price_asc' | 'price_desc' | 'name'

  const ShopFilterState({
    this.searchQuery = '',
    this.discipline = 'All',
    this.productType = 'All',
    this.sortBy = 'newest',
  });

  ShopFilterState copyWith({
    String? searchQuery,
    String? discipline,
    String? productType,
    String? sortBy,
  }) {
    return ShopFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      discipline: discipline ?? this.discipline,
      productType: productType ?? this.productType,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class ShopFilterNotifier extends StateNotifier<ShopFilterState> {
  ShopFilterNotifier() : super(const ShopFilterState());

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setDiscipline(String d) => state = state.copyWith(discipline: d);
  void setProductType(String t) => state = state.copyWith(productType: t);
  void setSort(String s) => state = state.copyWith(sortBy: s);
  void reset() => state = const ShopFilterState();
}

final shopFilterProvider =
    StateNotifierProvider<ShopFilterNotifier, ShopFilterState>((ref) {
      return ShopFilterNotifier();
    });

/// Filtered + sorted product list derived from productsProvider and filters
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((
  ref,
) {
  final productsAsync = ref.watch(productsProvider);
  final filter = ref.watch(shopFilterProvider);

  return productsAsync.whenData((products) {
    var result = products.where((p) {
      final matchesQuery =
          filter.searchQuery.isEmpty ||
          p.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(
            filter.searchQuery.toLowerCase(),
          );
      final matchesDiscipline =
          filter.discipline == 'All' ||
          p.disciplines.contains(filter.discipline);
      final matchesType =
          filter.productType == 'All' || p.categoryId == filter.productType;
      return matchesQuery && matchesDiscipline && matchesType;
    }).toList();

    switch (filter.sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default: // newest
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  });
});
