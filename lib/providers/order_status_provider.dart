import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import 'auth_provider.dart';
import 'order_provider.dart';

/// A single order-status transition detected from the live order stream.
class OrderStatusUpdate {
  final String orderId;
  final String orderNumber;
  final String previousStatus;
  final String newStatus;
  final DateTime detectedAt;

  const OrderStatusUpdate({
    required this.orderId,
    required this.orderNumber,
    required this.previousStatus,
    required this.newStatus,
    required this.detectedAt,
  });

  bool get isCancelled => newStatus.toLowerCase() == 'cancelled';

  bool get isCompleted => newStatus.toLowerCase() == 'completed';

  String get message => 'Your order #$orderNumber is now $newStatus.';
}

/// Pure diffing logic for order statuses.
///
/// The first snapshot is treated as the baseline so signing in never produces
/// a burst of notifications for existing orders.
class OrderStatusTracker {
  final Map<String, String> _knownStatuses = <String, String>{};
  bool _seeded = false;

  /// Returns transitions that happened since the previous [ingest] call.
  ///
  /// Returns `null` for the first snapshot and when nothing changed.
  List<OrderStatusUpdate>? ingest(
    List<OrderModel> orders, {
    DateTime? now,
  }) {
    if (!_seeded) {
      for (final order in orders) {
        _knownStatuses[order.id] = order.orderStatus;
      }
      _seeded = true;
      return null;
    }

    final updates = <OrderStatusUpdate>[];
    for (final order in orders) {
      final previousStatus = _knownStatuses[order.id];
      if (previousStatus != null && previousStatus != order.orderStatus) {
        updates.add(
          OrderStatusUpdate(
            orderId: order.id,
            orderNumber: _shortNumber(order.id),
            previousStatus: previousStatus,
            newStatus: order.orderStatus,
            detectedAt: now ?? DateTime.now(),
          ),
        );
      }
      _knownStatuses[order.id] = order.orderStatus;
    }

    return updates.isEmpty ? null : updates;
  }

  void reset() {
    _knownStatuses.clear();
    _seeded = false;
  }

  static String _shortNumber(String id) {
    final end = id.length > 8 ? 8 : id.length;
    return id.substring(0, end).toUpperCase();
  }
}

/// Emits the most recent status transition detected on the customer's orders.
///
/// The underlying [customerOrdersProvider] is a Firestore stream, so an admin
/// status change is pushed to the app without polling.
final orderStatusUpdateProvider =
    NotifierProvider<OrderStatusUpdateNotifier, OrderStatusUpdate?>(
      OrderStatusUpdateNotifier.new,
    );

class OrderStatusUpdateNotifier extends Notifier<OrderStatusUpdate?> {
  final OrderStatusTracker _tracker = OrderStatusTracker();
  String? _lastCustomerId;

  @override
  OrderStatusUpdate? build() {
    // Seed immediately if the stream is already populated (e.g. returning to
    // this screen after the provider has cached a snapshot).
    final initial = ref.read(customerOrdersProvider).valueOrNull;
    if (initial != null) {
      _tracker.ingest(initial);
    }

    ref.listen<AsyncValue<List<OrderModel>>>(customerOrdersProvider, (
      previous,
      next,
    ) {
      final orders = next.valueOrNull;
      if (orders == null) return;

      final customerId = ref.read(currentCustomerIdProvider);
      if (customerId != _lastCustomerId) {
        _lastCustomerId = customerId;
        _tracker.reset();
      }

      final updates = _tracker.ingest(orders);
      if (updates == null || updates.isEmpty) return;

      // The latest transition is the most relevant alert. Rare simultaneous
      // multi-order changes still surface one banner per stream emission.
      state = updates.last;
    });

    return null;
  }
}
