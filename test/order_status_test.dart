import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/features/notifications/widgets/order_status_banner_host.dart';
import 'package:mcommerce_app/models/order_model.dart';
import 'package:mcommerce_app/providers/order_status_provider.dart';

OrderModel _order(String id, String status, {bool legacyField = false}) {
  return OrderModel.fromMap({
    'customerId': 'customer-1',
    'items': const [],
    'shippingAddress': const {},
    'subtotal': 100.0,
    'shippingFee': 0.0,
    'total': 100.0,
    'paymentMethod': 'COD',
    if (legacyField) 'status': status else 'orderStatus': status,
  }, id);
}

void main() {
  group('OrderModel orderStatus', () {
    test('reads the new orderStatus field', () {
      final order = _order('order-12345678', 'Shipped');
      expect(order.orderStatus, 'Shipped');
      expect(order.status, 'Shipped'); // backwards-compatible alias
    });

    test('falls back to the legacy status field', () {
      final order = _order('order-legacy', 'Completed', legacyField: true);
      expect(order.orderStatus, 'Completed');
    });

    test('writes both orderStatus and status for compatibility', () {
      final map = _order('order-write', 'Processing').toMap();
      expect(map['orderStatus'], 'Processing');
      expect(map['status'], 'Processing');
    });

    test('defaults to Pending when neither field is present', () {
      final order = OrderModel.fromMap({
        'customerId': 'customer-1',
        'paymentMethod': 'COD',
      }, 'order-empty');
      expect(order.orderStatus, 'Pending');
    });
  });

  group('OrderStatusTracker', () {
    test('does not emit on the initial baseline snapshot', () {
      final tracker = OrderStatusTracker();
      final updates = tracker.ingest([
        _order('order-1', 'Pending'),
        _order('order-2', 'Processing'),
      ]);
      expect(updates, isNull);
    });

    test('emits only orders whose status changed', () {
      final tracker = OrderStatusTracker();
      tracker.ingest([
        _order('order-1', 'Pending'),
        _order('order-2', 'Processing'),
      ]);

      final updates = tracker.ingest([
        _order('order-1', 'Shipped'),
        _order('order-2', 'Processing'),
      ]);

      expect(updates, isNotNull);
      expect(updates, hasLength(1));
      expect(updates!.single.orderId, 'order-1');
      expect(updates.single.previousStatus, 'Pending');
      expect(updates.single.newStatus, 'Shipped');
      expect(updates.single.orderNumber, 'ORDER-1');
      expect(updates.single.message, contains('Shipped'));
    });

    test('does not emit for a newly created order', () {
      final tracker = OrderStatusTracker();
      tracker.ingest([_order('order-1', 'Pending')]);

      final updates = tracker.ingest([
        _order('order-1', 'Pending'),
        _order('order-2', 'Pending'),
      ]);
      expect(updates, isNull);
    });

    test('flags cancellations', () {
      final tracker = OrderStatusTracker();
      tracker.ingest([_order('order-1', 'Processing')]);

      final updates = tracker.ingest([_order('order-1', 'Cancelled')]);
      expect(updates!.single.isCancelled, isTrue);
      expect(updates.single.isCompleted, isFalse);
    });

    test('reset re-seeds without emitting alerts', () {
      final tracker = OrderStatusTracker();
      tracker.ingest([_order('order-1', 'Pending')]);
      tracker.reset();

      expect(tracker.ingest([_order('order-1', 'Shipped')]), isNull);
    });
  });

  testWidgets('shows an in-app alert when a status update is emitted', (
    tester,
  ) async {
    final notifier = _FakeOrderStatusUpdateNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderStatusUpdateProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          builder: (context, child) =>
              OrderStatusBannerHost(child: child ?? const SizedBox.shrink()),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    notifier.emit(
      OrderStatusUpdate(
        orderId: 'order-1234567890',
        orderNumber: 'ORDER-12',
        previousStatus: 'Processing',
        newStatus: 'Shipped',
        detectedAt: DateTime(2026, 11, 8),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Order update'), findsOneWidget);
    expect(find.textContaining('is now Shipped'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);
  });
}

class _FakeOrderStatusUpdateNotifier extends OrderStatusUpdateNotifier {
  @override
  OrderStatusUpdate? build() => null;

  void emit(OrderStatusUpdate update) => state = update;
}
