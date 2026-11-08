import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item_model.dart';

class ShippingAddressSnapshot {
  final String fullName;
  final String email;
  final String phone;
  final String street;
  final String city;
  final String province;
  final String postalCode;

  ShippingAddressSnapshot({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.street,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'street': street,
      'city': city,
      'province': province,
      'postalCode': postalCode,
    };
  }

  factory ShippingAddressSnapshot.fromMap(Map<String, dynamic> map) {
    return ShippingAddressSnapshot(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
    );
  }

  String get fullAddress => '$street, $city, $province $postalCode';
}

class OrderModel {
  final String id;
  final String customerId;
  final List<CartItemModel> items;
  final ShippingAddressSnapshot shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status; // Pending, Processing, Shipped, Completed, Cancelled
  final String paymentMethod; // 'COD', 'GCash'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    this.status = 'Pending',
    required this.paymentMethod,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'];
    final itemsList = <CartItemModel>[];
    if (rawItems is List) {
      for (var i = 0; i < rawItems.length; i++) {
        final entry = rawItems[i];
        if (entry is Map) {
          try {
            itemsList.add(
              CartItemModel.fromSnapshotMap(
                Map<String, dynamic>.from(entry),
                'item_$i',
              ),
            );
          } catch (e, st) {
            // Skip malformed item snapshots rather than crashing order parsing.
            // ignore: avoid_print
            print('OrderModel.fromMap: skipping malformed item $i: $e\n$st');
          }
        }
      }
    }

    DateTime createdAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    final rawShipping = map['shippingAddress'];
    final shippingMap = rawShipping is Map
        ? Map<String, dynamic>.from(rawShipping)
        : <String, dynamic>{};

    final payment = map['paymentMethod']?.toString().trim();
    final status = map['status']?.toString().trim();

    return OrderModel(
      id: id,
      customerId: map['customerId']?.toString() ?? '',
      items: itemsList,
      shippingAddress: ShippingAddressSnapshot.fromMap(shippingMap),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: (status == null || status.isEmpty) ? 'Pending' : status,
      paymentMethod: (payment == null || payment.isEmpty) ? 'COD' : payment,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'items': items.map((e) => e.toSnapshotMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isEligibleForCancellation => status.toLowerCase() == 'pending';

  /// Total number of units across all item snapshots.
  int get itemCount => items.fold<int>(0, (acc, item) => acc + item.quantity);
}
