class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final String selectedSize;
  final String selectedColor;
  final String variantId;
  final int quantity;
  final int availableStock;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.selectedSize,
    required this.selectedColor,
    required this.variantId,
    required this.quantity,
    required this.availableStock,
  });

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    int? quantity,
    int? availableStock,
  }) {
    return CartItemModel(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      unitPrice: unitPrice,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
      variantId: variantId,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  Map<String, dynamic> toSnapshotMap() {
    return <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'variantId': variantId,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory CartItemModel.fromSnapshotMap(Map<String, dynamic> map, String id) {
    final qty = (map['quantity'] as num?)?.toInt() ?? 1;
    final price = (map['unitPrice'] as num?)?.toDouble() ?? 0.0;
    return CartItemModel(
      id: id,
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? 'Product',
      productImage: map['productImage']?.toString() ?? '',
      unitPrice: price.isFinite ? price : 0.0,
      selectedSize: map['selectedSize']?.toString().trim().isNotEmpty == true
          ? map['selectedSize'].toString()
          : 'M',
      selectedColor: map['selectedColor']?.toString().trim().isNotEmpty == true
          ? map['selectedColor'].toString()
          : 'Black',
      variantId: map['variantId']?.toString() ?? '',
      quantity: qty < 1 ? 1 : qty,
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 99,
    );
  }
}
