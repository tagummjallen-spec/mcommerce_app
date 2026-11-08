import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/features/products/widgets/cart_notification.dart';

void main() {
  test('product notifications auto-dismiss after two seconds', () {
    final snackBar = buildProductNotificationSnackBar(
      message: 'Added to cart!',
      backgroundColor: Colors.green,
      actionTextColor: Colors.white,
      onViewCart: () {},
    );

    expect(snackBar.duration, const Duration(seconds: 2));
  });
}
