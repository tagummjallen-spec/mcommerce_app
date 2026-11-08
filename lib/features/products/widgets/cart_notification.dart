import 'package:flutter/material.dart';

SnackBar buildProductNotificationSnackBar({
  required String message,
  required Color backgroundColor,
  required Color actionTextColor,
  required VoidCallback onViewCart,
}) {
  return SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    action: SnackBarAction(
      label: 'VIEW CART',
      textColor: actionTextColor,
      onPressed: onViewCart,
    ),
  );
}
