import 'package:flutter_test/flutter_test.dart';
import 'package:mcommerce_app/models/user_model.dart';

void main() {
  test('address fields round-trip through the Firestore map', () {
    final user = UserModel(
      uid: 'u1',
      email: 'customer@example.com',
      streetAddress: 'Blk 12 Lot 3, Sampaguita St.',
      barangay: 'San Isidro',
      cityMunicipality: 'Binangonan',
      province: 'Rizal',
      postalCode: '1940',
    );

    final restored = UserModel.fromMap(user.toMap(), 'u1');

    expect(restored.streetAddress, 'Blk 12 Lot 3, Sampaguita St.');
    expect(restored.barangay, 'San Isidro');
    expect(restored.cityMunicipality, 'Binangonan');
    expect(restored.province, 'Rizal');
    expect(restored.postalCode, '1940');
    expect(restored.hasSavedAddress, isTrue);
    expect(restored.hasCompleteAddress, isTrue);
    expect(
      restored.formattedAddress,
      'Blk 12 Lot 3, Sampaguita St., San Isidro, Binangonan, Rizal, 1940',
    );
  });

  test('legacy documents map city into cityMunicipality', () {
    final restored = UserModel.fromMap({
      'street': '1 Legacy Road',
      'city': 'Old City',
      'barangay': 'Old Barangay',
    }, 'u2');

    expect(restored.streetAddress, '1 Legacy Road');
    expect(restored.cityMunicipality, 'Old City');
    expect(restored.barangay, 'Old Barangay');
    expect(restored.province, '');
    expect(restored.postalCode, '');
    expect(restored.hasCompleteAddress, isFalse);
  });

  test('copyWith updates individual address fields', () {
    final user = UserModel(uid: 'u3', email: 'a@b.co');

    final updated = user.copyWith(
      cityMunicipality: 'Antipolo',
      postalCode: '1870',
    );

    expect(updated.streetAddress, '');
    expect(updated.cityMunicipality, 'Antipolo');
    expect(updated.postalCode, '1870');
    expect(user.cityMunicipality, '');
  });
}
