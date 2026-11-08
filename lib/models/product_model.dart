import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductVariant {
  final String id;
  final String size;
  final String color;
  final int stock;

  ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.stock,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map, String id) {
    int parsedStock = 0;
    final stockData = map['stock'];
    if (stockData is num) {
      parsedStock = stockData.toInt();
    } else if (stockData != null) {
      parsedStock = int.tryParse(stockData.toString()) ?? 0;
    }
    return ProductVariant(
      id: id,
      size: map['size']?.toString() ?? 'Standard',
      color: map['color']?.toString() ?? 'Standard',
      stock: parsedStock,
    );
  }

  Map<String, dynamic> toMap() {
    return {'size': size, 'color': color, 'stock': stock};
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId; // product type
  final List<String> disciplines;
  final List<String> images;
  final bool isActive;
  final List<ProductVariant> variants;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.disciplines,
    required this.images,
    this.isActive = true,
    required this.variants,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    try {
      var rawVariants = map['variants'];
      List<ProductVariant> variantList = [];
      if (rawVariants is List) {
        for (var i = 0; i < rawVariants.length; i++) {
          final entry = rawVariants[i];
          if (entry is Map<String, dynamic>) {
            variantList.add(ProductVariant.fromMap(entry, 'var_$i'));
          } else if (entry is Map) {
            variantList.add(
              ProductVariant.fromMap(
                Map<String, dynamic>.from(entry),
                'var_$i',
              ),
            );
          } else {
            continue;
          }
        }
      } else if (rawVariants is Map<String, dynamic>) {
        rawVariants.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            variantList.add(ProductVariant.fromMap(value, key));
          } else if (value is Map) {
            variantList.add(
              ProductVariant.fromMap(Map<String, dynamic>.from(value), key),
            );
          }
        });
      }

      // Default fallback variant if none provided
      if (variantList.isEmpty) {
        variantList = [
          ProductVariant(id: 'default_m', size: 'M', color: 'Black', stock: 25),
          ProductVariant(id: 'default_l', size: 'L', color: 'Black', stock: 15),
        ];
      }

      double parsedPrice = 0.0;
      final priceData = map['price'];
      if (priceData is num) {
        parsedPrice = priceData.toDouble();
      } else if (priceData != null) {
        parsedPrice = double.tryParse(priceData.toString()) ?? 0.0;
      }

      bool parsedIsActive = true;
      if (map['isActive'] is bool) {
        parsedIsActive = map['isActive'] as bool;
      }

      List<String> parsedImages = [];
      if (map['images'] is List) {
        parsedImages = (map['images'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      }

      List<String> parsedDisciplines = [];
      if (map['disciplines'] is List) {
        parsedDisciplines = (map['disciplines'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
      }

      DateTime parsedCreatedAt = DateTime.now();
      if (map['createdAt'] is Timestamp) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] != null) {
        parsedCreatedAt =
            DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }

      return ProductModel(
        id: id,
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        price: parsedPrice,
        categoryId:
            (map['categoryId'] ?? map['productTypeId'])?.toString() ??
            'General',
        disciplines: parsedDisciplines,
        images: parsedImages,
        isActive: parsedIsActive,
        variants: variantList,
        createdAt: parsedCreatedAt,
      );
    } catch (e, st) {
      debugPrint('Error parsing ProductModel for id: $id');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      debugPrint('Raw data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'disciplines': disciplines,
      'images': images,
      'isActive': isActive,
      'variants': variants.map((v) => v.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get totalStock => variants.fold(0, (acc, item) => acc + item.stock);
  bool get isInStock => totalStock > 0;
}
