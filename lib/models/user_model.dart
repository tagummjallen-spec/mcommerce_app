import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final String streetAddress;
  final String barangay;
  final String cityMunicipality;
  final String province;
  final String postalCode;
  final String role; // 'customer' or 'admin'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    String? displayName,
    String? fullName,
    required this.email,
    String? phoneNumber,
    String? phone,
    this.profileImageUrl = '',
    this.streetAddress = '',
    this.barangay = '',
    this.cityMunicipality = '',
    this.province = '',
    this.postalCode = '',
    this.role = 'customer',
    DateTime? createdAt,
  }) : displayName = displayName ?? fullName ?? '',
       phoneNumber = phoneNumber ?? phone ?? '',
       createdAt = createdAt ?? DateTime.now();

  /// Backwards-compatible aliases used by older screens.
  String get fullName => displayName;
  String get phone => phoneNumber;

  /// True when the account has any saved delivery address data worth showing.
  bool get hasSavedAddress =>
      streetAddress.trim().isNotEmpty || cityMunicipality.trim().isNotEmpty;

  /// True when every field needed to ship an order is present.
  bool get hasCompleteAddress =>
      streetAddress.trim().isNotEmpty &&
      barangay.trim().isNotEmpty &&
      cityMunicipality.trim().isNotEmpty &&
      province.trim().isNotEmpty &&
      postalCode.trim().isNotEmpty;

  /// Human-readable single-line address used in cards and order snapshots.
  String get formattedAddress {
    final parts = <String>[];
    final street = streetAddress.trim();
    final brgy = barangay.trim();
    final city = cityMunicipality.trim();
    final prov = province.trim();
    final postal = postalCode.trim();

    if (street.isNotEmpty) parts.add(street);
    if (brgy.isNotEmpty) parts.add(brgy);
    final cityProvince = [city, prov].where((p) => p.isNotEmpty).join(', ');
    if (cityProvince.isNotEmpty) parts.add(cityProvince);
    if (postal.isNotEmpty) parts.add(postal);
    return parts.join(', ');
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt != null) {
      parsedCreatedAt =
          DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
    }

    return UserModel(
      uid: id,
      displayName:
          map['displayName']?.toString() ??
          map['fullName']?.toString() ??
          map['name']?.toString() ??
          '',
      email: map['email']?.toString() ?? '',
      phoneNumber:
          map['phoneNumber']?.toString() ?? map['phone']?.toString() ?? '',
      profileImageUrl: map['profileImageUrl']?.toString() ?? '',
      streetAddress:
          map['streetAddress']?.toString() ?? map['street']?.toString() ?? '',
      barangay: map['barangay']?.toString() ?? '',
      cityMunicipality:
          map['cityMunicipality']?.toString() ??
          map['city']?.toString() ??
          '',
      province: map['province']?.toString() ?? '',
      postalCode:
          map['postalCode']?.toString() ?? map['postal']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'fullName': displayName, // legacy key
      'email': email,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber, // legacy key
      'profileImageUrl': profileImageUrl,
      'streetAddress': streetAddress,
      'barangay': barangay,
      'cityMunicipality': cityMunicipality,
      'province': province,
      'postalCode': postalCode,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? phone,
    String? profileImageUrl,
    String? streetAddress,
    String? barangay,
    String? cityMunicipality,
    String? province,
    String? postalCode,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? fullName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? phone ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      streetAddress: streetAddress ?? this.streetAddress,
      barangay: barangay ?? this.barangay,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
