import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/models/cart_item_model.dart';
import 'package:mcommerce_app/providers/cart_provider.dart';

CartItemModel _item(
  String id, {
  bool selected = true,
  int quantity = 1,
  double unitPrice = 100,
}) {
  return CartItemModel(
    id: id,
    productId: 'product_$id',
    productName: 'Product $id',
    productImage: '',
    unitPrice: unitPrice,
    selectedSize: 'M',
    selectedColor: 'Black',
    variantId: 'var_0',
    quantity: quantity,
    availableStock: 20,
    selected: selected,
  );
}

void main() {
  test('subtotal only includes checked items', () {
    final state = CartState(
      items: [
        _item('a', selected: true),
        _item('b', selected: false, quantity: 2),
      ],
    );

    expect(state.selectedItems.map((item) => item.id), ['a']);
    expect(state.selectedCount, 1);
    expect(state.hasSelection, isTrue);
    expect(state.allSelected, isFalse);
    expect(state.subtotal, 100);
    expect(state.fullSubtotal, 300);
  });

  test('select-all helpers reflect every item', () {
    final all = CartState(items: [_item('a'), _item('b')]);
    expect(all.allSelected, isTrue);
    expect(all.selectedCount, 2);
    expect(all.subtotal, 200);

    final none = CartState(
      items: [_item('a', selected: false), _item('b', selected: false)],
    );
    expect(none.hasSelection, isFalse);
    expect(none.allSelected, isFalse);
    expect(none.subtotal, 0);
  });

  test('copyWith can toggle selection without losing item data', () {
    final item = _item('a');
    final deselected = item.copyWith(selected: false);

    expect(deselected.selected, isFalse);
    expect(deselected.id, 'a');
    expect(deselected.quantity, item.quantity);
    expect(deselected.unitPrice, item.unitPrice);
  });

  test('snapshot maps persist the checked state', () {
    final selected = _item('a', selected: true).toSnapshotMap();
    final unselected = _item('b', selected: false).toSnapshotMap();

    expect(selected['selected'], isTrue);
    expect(unselected['selected'], isFalse);

    final restored = CartItemModel.fromSnapshotMap(unselected, 'b');
    expect(restored.selected, isFalse);

    // Legacy cart documents without the field default to selected.
    final legacy = Map<String, dynamic>.from(unselected)..remove('selected');
    expect(CartItemModel.fromSnapshotMap(legacy, 'b').selected, isTrue);
  });
}
