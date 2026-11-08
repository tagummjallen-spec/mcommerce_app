import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

/// Live stream of the signed-in customer's orders (empty list for guests).
final customerOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield <OrderModel>[];
    return;
  }
  yield* ref.watch(orderServiceProvider).watchCustomerOrders(user.uid);
});

/// Single order lookup; null when the order does not exist.
final orderProvider =
    FutureProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).fetchOrder(orderId);
});
