import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';

/// Reusable product card used in grids and horizontal lists.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({super.key, required this.product, this.width = 180});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: product.images.isNotEmpty
                    ? _buildProductImage(product.images.first)
                    : _fallbackImage(),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.isNotEmpty
                        ? product.category
                        : product.disciplines.take(2).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.tertiaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      if (!product.isInStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    final path = imagePath.trim();
    if (path.isEmpty) return _fallbackImage();

    if (path.startsWith('data:image/')) {
      try {
        final commaIndex = path.indexOf(',');
        if (commaIndex >= 0 && commaIndex < path.length - 1) {
          return Image.memory(
            base64Decode(path.substring(commaIndex + 1)),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackImage(),
          );
        }
      } catch (e) {
        debugPrint('DATA URL IMAGE ERROR: $e');
      }
      return _fallbackImage();
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ASSET IMAGE ERROR: $error for $path');
          return _fallbackImage();
        },
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.cardSurface,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('NETWORK IMAGE ERROR: $error for $path');
          return _fallbackImage();
        },
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.cardSurface,
      child: const Center(
        child: Icon(
          Icons.sports_martial_arts,
          color: AppColors.tertiaryText,
          size: 36,
        ),
      ),
    );
  }
}
