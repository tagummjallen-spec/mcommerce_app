import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/features/products/screens/shop_screen.dart';
import 'package:mcommerce_app/models/product_model.dart';
import 'package:mcommerce_app/providers/cart_provider.dart';
import 'package:mcommerce_app/providers/product_provider.dart';

void main() {
  testWidgets('shop filter and sort row fits a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(250, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredProductsProvider.overrideWith(
            (ref) => const AsyncData<List<ProductModel>>([]),
          ),
          cartItemCountProvider.overrideWith((ref) => 0),
        ],
        child: const MaterialApp(home: ShopScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
