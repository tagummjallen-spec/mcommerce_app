import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

/// Persists the authenticated user's cart under carts/{uid}/items.
/// Guest carts are kept in memory by the Riverpod provider instead.
class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) =>
      _firestore.collection('carts').doc(uid).collection('items');

  Future<void> saveCart(String uid, List<CartItemModel> items) async {
    final batch = _firestore.batch();
    final existing = await _itemsRef(uid).get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final item in items) {
      final doc = _itemsRef(uid).doc(item.id);
      batch.set(doc, item.toSnapshotMap());
    }
    await batch.commit();
  }

  Future<List<CartItemModel>> loadCart(String uid) async {
    final snapshot = await _itemsRef(uid).get();
    return snapshot.docs
        .map((doc) => CartItemModel.fromSnapshotMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> clearCart(String uid) async {
    final existing = await _itemsRef(uid).get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
