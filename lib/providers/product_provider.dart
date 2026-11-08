// Riverpod providers for the product catalog and shop filters.
// The underlying implementation lives in the FirestoreService file.
export '../services/firestore_service.dart'
    show
        firestoreServiceProvider,
        productsProvider,
        productProvider,
        ShopFilterState,
        ShopFilterNotifier,
        shopFilterProvider,
        filteredProductsProvider;
    