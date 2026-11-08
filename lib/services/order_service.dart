import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';

/// Trusted order operations.
///
/// Cloud Firestore requires that every `transaction.get` happens before the
/// first `transaction.write`, so each method below follows the pattern:
///   1. READ + validate all involved documents
///   2. WRITE the resulting changes atomically
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _orders => _firestore.collection('orders');
  CollectionReference get _products => _firestore.collection('products');

  /// Atomically:
  /// 1. Validates prices and stock against Firestore (authoritative data)
  /// 2. Creates the order document
  ///
  /// Stock is deducted later, when an admin marks the order Completed.
  ///
  /// Returns the new orderId. Throws a user-friendly message when validation
  /// fails (out of stock / price change / inactive product).
  Future<String> placeOrder({
    required String customerId,
    required List<CartItemModel> items,
    required ShippingAddressSnapshot shipping,
    required String paymentMethod,
    required double shippingFee,
  }) async {
    if (customerId.trim().isEmpty) {
      throw Exception('You must be signed in to place an order.');
    }
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    // Normalize payment method to known values to avoid null/odd data.
    final normalizedPayment = () {
      final p = paymentMethod.trim();
      if (p.isEmpty) return 'COD';
      final lower = p.toLowerCase();
      if (lower.contains('gcash')) return 'GCash';
      if (lower.contains('cod') || lower.contains('cash')) return 'COD';
      return p;
    }();

    final orderRef = _orders.doc();
    debugPrint(
      'OrderService.placeOrder: start order=${orderRef.id} customer=$customerId '
      'items=${items.length} payment=$normalizedPayment shipping=$shippingFee',
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // ============ PHASE 1: READ + VALIDATE ============
        final productSnaps = <String, DocumentSnapshot>{};
        for (final item in items) {
          if (productSnaps.containsKey(item.productId)) continue;
          final snap = await transaction.get(_products.doc(item.productId));
          productSnaps[item.productId] = snap;
        }

        double subtotal = 0;

        for (final item in items) {
          final snap = productSnaps[item.productId];
          if (snap == null || !snap.exists) {
            throw Exception('"${item.productName}" is no longer available.');
          }
          final rawData = snap.data();
          if (rawData is! Map) {
            throw Exception('Invalid product data for "${item.productName}".');
          }
          final data = Map<String, dynamic>.from(rawData);
          if (data['isActive'] == false) {
            throw Exception('"${item.productName}" is no longer for sale.');
          }

          // Validate against the current authoritative price.
          final currentPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
          if (currentPrice != item.unitPrice) {
            throw Exception(
              'Price of "${item.productName}" changed to ₱${currentPrice.toStringAsFixed(2)}. Please review your cart.',
            );
          }

          // Locate the variant and validate stock.
          final rawVariants = data['variants'];
          bool stockValidated = false;
          if (rawVariants is List) {
            final index = int.tryParse(item.variantId.replaceFirst('var_', ''));
            if (index != null && index >= 0 && index < rawVariants.length) {
              final v = rawVariants[index];
              if (v is Map) {
                final stock = (v['stock'] as num?)?.toInt() ?? 0;
                if (stock < item.quantity) {
                  throw Exception(
                    'Insufficient stock for "${item.productName}" (${item.selectedSize}/${item.selectedColor}). Only $stock left.',
                  );
                }
                stockValidated = true;
              }
            }
          } else if (rawVariants is Map) {
            final variantsMap = Map<String, dynamic>.from(rawVariants);
            final v = variantsMap[item.variantId];
            if (v is Map) {
              final stock = (v['stock'] as num?)?.toInt() ?? 0;
              if (stock < item.quantity) {
                throw Exception(
                  'Insufficient stock for "${item.productName}" (${item.selectedSize}/${item.selectedColor}). Only $stock left.',
                );
              }
              stockValidated = true;
            }
          }
          if (!stockValidated && data['stock'] is num) {
            final stock = (data['stock'] as num).toInt();
            if (stock < item.quantity) {
              throw Exception(
                'Insufficient stock for "${item.productName}". Only $stock left.',
              );
            }
            stockValidated = true;
          }
          if (!stockValidated) {
            throw Exception(
              '"${item.productName}" has no available stock information.',
            );
          }

          subtotal += currentPrice * item.quantity;
        }

        // ============ PHASE 2: WRITE ============
        // Stock is intentionally NOT deducted here. Inventory is deducted
        // exactly once when an admin marks the order as Completed, so pending
        // and cancelled orders never consume stock.
        // Create the order document.
        final safeShippingFee = shippingFee.isFinite ? shippingFee : 0.0;
        final total = subtotal + safeShippingFee;
        final orderData = <String, dynamic>{
          'customerId': customerId,
          'items': items.map((e) => e.toSnapshotMap()).toList(),
          'shippingAddress': shipping.toMap(),
          'subtotal': subtotal,
          'shippingFee': safeShippingFee,
          'total': total,
          'paymentMethod': normalizedPayment,
          'paymentStatus': normalizedPayment == 'COD' ? 'Unpaid' : 'Paid',
          'status': 'Pending',
          // Explicitly false: admin fulfillment deducts stock on completion.
          // Legacy orders without this field already reserved stock at
          // placement, so the admin service treats a missing flag as deducted.
          'inventoryDeducted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        debugPrint('OrderService.placeOrder: writing order ${orderRef.id}');
        transaction.set(orderRef, orderData);
      });

      debugPrint('OrderService.placeOrder: success order=${orderRef.id}');
      return orderRef.id;
    } on FirebaseException catch (e, st) {
      debugPrint(
        'OrderService.placeOrder: FirebaseException code=${e.code} '
        'message=${e.message}\n$st',
      );
      throw Exception(_friendlyFirebaseError(e));
    } catch (e, st) {
      debugPrint('OrderService.placeOrder: error $e\n$st');
      rethrow;
    }
  }

  String _friendlyFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Checkout failed: permission denied. Please sign in again or contact support.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Checkout failed due to a network issue. Please check your connection and try again.';
      case 'failed-precondition':
        return 'Checkout failed due to a database configuration issue. Please try again later.';
      case 'aborted':
        return 'Checkout was interrupted. Please try again.';
      default:
        return 'Checkout failed (${e.code}). ${e.message ?? 'Please try again.'}';
    }
  }

  /// Atomically cancels a Pending order.
  ///
  /// Legacy orders that reserved stock at placement are restored. Newer orders
  /// (`inventoryDeducted == false`) have nothing to restore because stock is
  /// only deducted when the order is completed. Duplicate submissions are
  /// rejected because the status check and the status change occur inside the
  /// same transaction.
  Future<void> cancelOrder(String orderId) async {
    final orderRef = _orders.doc(orderId);

    await _firestore.runTransaction((transaction) async {
      // ============ PHASE 1: READ + VALIDATE ============
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Order not found.');
      }
      final data = orderSnap.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      if (status != 'Pending') {
        throw Exception('Only pending orders can be cancelled.');
      }

      // New orders are not deducted until fulfilment, so cancelling them has
      // nothing to restore. Legacy orders (missing flag) already reserved
      // stock at placement, so keep restoring those.
      final shouldRestore = data['inventoryDeducted'] != false;

      if (shouldRestore) {
        final items = List<Map<String, dynamic>>.from(
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        );

        // productId -> total quantity to restore
        final restoreDeltas = <String, int>{};
        for (final item in items) {
          final pid = item['productId'] as String? ?? '';
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          restoreDeltas[pid] = (restoreDeltas[pid] ?? 0) + qty;
        }

        final productSnaps = <String, DocumentSnapshot>{};
        for (final pid in restoreDeltas.keys) {
          final snap = await transaction.get(_products.doc(pid));
          productSnaps[pid] = snap;
        }

        // ============ PHASE 2: WRITE ============
        for (final entry in restoreDeltas.entries) {
          final snap = productSnaps[entry.key];
          if (snap == null || !snap.exists) continue;
          final pData = snap.data() as Map<String, dynamic>;
          final rawVariants = pData['variants'];

          if (rawVariants is List) {
            final perIndex = <int, int>{};
            for (final item in items) {
              if (item['productId'] != entry.key) continue;
              final index = int.tryParse(
                (item['variantId'] as String? ?? '').replaceFirst('var_', ''),
              );
              if (index != null) {
                perIndex[index] =
                    (perIndex[index] ?? 0) +
                    ((item['quantity'] as num?)?.toInt() ?? 0);
              }
            }
            final newVariants = <dynamic>[];
            for (var i = 0; i < rawVariants.length; i++) {
              final v = Map<String, dynamic>.from(rawVariants[i] as Map);
              final stock = (v['stock'] as num?)?.toInt() ?? 0;
              v['stock'] = stock + (perIndex[i] ?? 0);
              newVariants.add(v);
            }
            transaction.update(_products.doc(entry.key), {
              'variants': newVariants,
            });
          } else if (rawVariants is Map<String, dynamic>) {
            final newVariants = Map<String, dynamic>.from(rawVariants);
            for (final item in items) {
              if (item['productId'] != entry.key) continue;
              final vid = item['variantId'] as String? ?? '';
              final v = newVariants[vid];
              if (v is Map) {
                final vMap = Map<String, dynamic>.from(v);
                final stock = (vMap['stock'] as num?)?.toInt() ?? 0;
                vMap['stock'] =
                    stock + ((item['quantity'] as num?)?.toInt() ?? 0);
                newVariants[vid] = vMap;
              }
            }
            transaction.update(_products.doc(entry.key), {
              'variants': newVariants,
            });
          } else if (pData['stock'] is num) {
            final stock = (pData['stock'] as num).toInt();
            transaction.update(_products.doc(entry.key), {
              'stock': stock + entry.value,
            });
          }
        }
      }

      // Guarded status flip: if another request already cancelled this order,
      // this transaction would have failed the status check above.
      transaction.update(orderRef, {
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Returns true when [userId] has at least one order whose status is
  /// exactly `Completed` or `Delivered` that contains [productId].
  ///
  /// Uses a single-field query (no composite index needed) and checks the
  /// status/items client-side so malformed legacy orders cannot break it.
  Future<bool> hasCompletedPurchase({
    required String userId,
    required String productId,
  }) async {
    if (userId.trim().isEmpty || productId.trim().isEmpty) return false;

    final snapshot = await _orders.where('customerId', isEqualTo: userId).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data is! Map) continue;

      final status = (data['status']?.toString() ?? '').trim().toLowerCase();
      if (status != 'completed' && status != 'delivered') continue;

      final items = data['items'];
      if (items is! List) continue;

      for (final item in items) {
        if (item is Map && (item['productId']?.toString() ?? '') == productId) {
          return true;
        }
      }
    }

    return false;
  }

  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    // Sorted client-side to avoid requiring a composite Firestore index.
    return _orders.where('customerId', isEqualTo: customerId).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return OrderModel.fromMap(data, doc.id);
      }).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<OrderModel?> fetchOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
