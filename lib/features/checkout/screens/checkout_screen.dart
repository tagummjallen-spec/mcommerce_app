import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/order_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalController = TextEditingController();

  String _paymentMethod = 'COD'; // COD | GCash (simulated)
  bool _isPlacingOrder = false;

  /// Whether the shipping form mirrors the saved profile address. The customer
  /// can switch to a one-off address for this order at any time.
  bool _useSavedAddress = false;
  bool _addressModeInitialized = false;
  bool _addressClearedByUser = false;

  /// Tracks the values we injected so later live profile emissions never
  /// overwrite text the customer has edited manually.
  final Map<TextEditingController, String> _appliedProfileValues = {};

  @override
  void initState() {
    super.initState();
    // Prefill from the signed-in profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final user = ref.read(authStateProvider).valueOrNull;
      _applyProfile(profile, user);
    });
  }

  void _applyProfile(UserModel? profile, User? user) {
    if (profile == null) {
      if (user != null) {
        _fillIfUntouched(_nameController, user.displayName ?? '');
        _fillIfUntouched(_emailController, user.email ?? '');
      }
      return;
    }

    if (!_addressModeInitialized) {
      _addressModeInitialized = true;
      _useSavedAddress = profile.hasCompleteAddress;
      _addressClearedByUser = false;
      if (mounted) setState(() {});
    }

    _fillIfUntouched(_nameController, profile.displayName);
    _fillIfUntouched(_emailController, profile.email);
    _fillIfUntouched(_phoneController, profile.phoneNumber);

    // Fill the address once from the profile, or keep it in sync while the
    // "saved address" option is active. Once the customer opts into a
    // different address we never overwrite what they type.
    if (_useSavedAddress || !_addressClearedByUser) {
      _fillIfUntouched(_streetController, profile.streetAddress);
      _fillIfUntouched(_barangayController, profile.barangay);
      _fillIfUntouched(_cityController, profile.cityMunicipality);
      _fillIfUntouched(_provinceController, profile.province);
      _fillIfUntouched(_postalController, profile.postalCode);
    }
  }

  void _setAddressFromProfile(UserModel profile) {
    _streetController.text = profile.streetAddress;
    _barangayController.text = profile.barangay;
    _cityController.text = profile.cityMunicipality;
    _provinceController.text = profile.province;
    _postalController.text = profile.postalCode;

    _appliedProfileValues[_streetController] = profile.streetAddress;
    _appliedProfileValues[_barangayController] = profile.barangay;
    _appliedProfileValues[_cityController] = profile.cityMunicipality;
    _appliedProfileValues[_provinceController] = profile.province;
    _appliedProfileValues[_postalController] = profile.postalCode;
  }

  void _clearAddressFields() {
    for (final controller in [
      _streetController,
      _barangayController,
      _cityController,
      _provinceController,
      _postalController,
    ]) {
      controller.clear();
      _appliedProfileValues.remove(controller);
    }
  }

  void _toggleAddressMode() {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile == null || !profile.hasCompleteAddress) return;
    setState(() {
      _useSavedAddress = !_useSavedAddress;
      _addressClearedByUser = !_useSavedAddress;
      if (_useSavedAddress) {
        _setAddressFromProfile(profile);
      } else {
        _clearAddressFields();
      }
    });
  }

  void _fillIfUntouched(TextEditingController controller, String value) {
    if (value.trim().isEmpty) return;
    final lastApplied = _appliedProfileValues[controller];
    final untouched =
        controller.text.trim().isEmpty ||
        (lastApplied != null && controller.text == lastApplied);
    if (!untouched) return;
    controller.text = value;
    _appliedProfileValues[controller] = value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  double get _subtotal => ref.read(cartProvider).subtotal;

  double get _shippingFee => _subtotal >= AppConstants.freeShippingThreshold
      ? 0
      : AppConstants.standardShippingFee;

  double get _total => _subtotal + _shippingFee;

  Future<void> _requireAuthThenPlaceOrder() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      // Guests must authenticate before checkout; the login screen returns
      // here (result == true) so the filled shipping form is preserved.
      final result = await context.push<bool>('/login?redirect=checkout');
      if (result == true || ref.read(authStateProvider).valueOrNull != null) {
        // Merge any guest cart with the user's saved Firestore cart.
        await ref.read(cartProvider.notifier).reloadForUser();
        if (mounted && ref.read(authStateProvider).valueOrNull != null) {
          await _placeOrder();
        }
      }
      return;
    }
    await _placeOrder();
  }

  Future<void> _placeOrder() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      _showSnack('Please sign in to place an order.', AppColors.error);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack('Please complete all shipping fields.', AppColors.warning);
      return;
    }

    final cart = ref.read(cartProvider);
    final selectedItems = cart.selectedItems;
    if (selectedItems.isEmpty) {
      _showSnack(
        cart.items.isEmpty
            ? 'Your cart is empty.'
            : 'Select at least one item to checkout.',
        AppColors.error,
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      debugPrint(
        'Checkout: placing order uid=${user.uid} method=$_paymentMethod '
        'items=${selectedItems.length} subtotal=$_subtotal '
        'shipping=$_shippingFee',
      );

      final shipping = ShippingAddressSnapshot(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        barangay: _barangayController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        postalCode: _postalController.text.trim(),
      );

      final orderId = await ref
          .read(orderServiceProvider)
          .placeOrder(
            customerId: user.uid,
            items: List.unmodifiable(selectedItems),
            shipping: shipping,
            paymentMethod: _paymentMethod,
            shippingFee: _shippingFee,
          );

      debugPrint(
        'Checkout: order created id=$orderId, clearing purchased items',
      );

      // Clear only the checked-out items; unchecked items stay in the cart.
      try {
        final purchasedIds = selectedItems.map((e) => e.id).toList();
        ref.read(cartProvider.notifier).clearPurchasedItems(purchasedIds);
      } catch (e, st) {
        debugPrint('Checkout: failed to clear purchased items: $e\n$st');
        // Non-fatal: order is already created.
      }

      if (!mounted) return;
      context.go('/order-confirmation/$orderId');
    } on FirebaseException catch (e, st) {
      debugPrint(
        'Checkout: FirebaseException code=${e.code} message=${e.message}\n$st',
      );
      if (!mounted) return;
      final msg = switch (e.code) {
        'permission-denied' =>
          'Checkout failed: permission denied. Please sign in again and try.',
        'unavailable' || 'network-request-failed' => 'Network error during checkout. Please check your connection and try again.',
        _ => 'Checkout failed (${e.code}). ${e.message ?? 'Please try again.'}',
      };
      _showSnack(msg, AppColors.error, seconds: 6);
    } catch (e, st) {
      debugPrint('Checkout: order submission failed: $e\n$st');
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      _showSnack(
        msg.isEmpty ? 'Checkout failed. Please try again.' : msg,
        AppColors.error,
        seconds: 6,
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showSnack(String message, Color color, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: seconds),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validateField(
    String? value,
    String fieldName, {
    bool optional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final savedProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canUseSavedAddress = savedProfile?.hasCompleteAddress ?? false;
    final useSavedAddress = _useSavedAddress && canUseSavedAddress;

    // Live profile updates (e.g. address saved from Edit profile) populate the
    // shipping form immediately without requiring a screen rebuild from scratch.
    ref.listen(currentUserProfileProvider, (previous, next) {
      if (!next.hasValue) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyProfile(next.value, ref.read(authStateProvider).valueOrNull);
      });
    });

    // If cart became empty and order finished, still allow viewing the form.
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(showBack: true),
      body: cart.selectedItems.isEmpty && !_isPlacingOrder
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.tertiaryText,
                    size: 48,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    cart.items.isEmpty
                        ? 'Nothing to checkout.'
                        : 'No items selected. Check items in your cart first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/shop'),
                    child: const Text('BROWSE SHOP'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Guest auth warning =====
                    if (isGuest)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are checking out as a guest. You will be asked to sign in before the order is placed.',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ===== Contact details =====
                    Text(
                      'CONTACT DETAILS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Juan Dela Cruz',
                      icon: Icons.person_outline,
                      validator: (v) => _validateField(v, 'Full name'),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '09XX XXX XXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => _validateField(v, 'Phone number'),
                    ),

                    const SizedBox(height: 26),

                    // ===== Delivery address =====
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'DELIVERY ADDRESS',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  color: AppColors.secondaryText,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        if (canUseSavedAddress)
                          TextButton(
                            onPressed: _toggleAddressMode,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              useSavedAddress
                                  ? 'USE A DIFFERENT ADDRESS'
                                  : 'USE SAVED ADDRESS',
                              style: TextStyle(
                                color: AppColors.lightAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (useSavedAddress && savedProfile != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryAccent.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryAccent,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved address',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    savedProfile.formattedAddress,
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _streetController,
                      label: 'Street Address / House no.',
                      hint: 'Blk 12 Lot 3, Sampaguita St.',
                      icon: Icons.home_outlined,
                      readOnly: useSavedAddress,
                      validator: (v) => _validateField(v, 'Street address'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _barangayController,
                            label: 'Barangay',
                            hint: 'Brgy. San Isidro',
                            icon: Icons.location_on_outlined,
                            readOnly: useSavedAddress,
                            validator: (v) => _validateField(v, 'Barangay'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _cityController,
                            label: 'City / Municipality',
                            hint: 'Binangonan',
                            icon: Icons.location_city_outlined,
                            readOnly: useSavedAddress,
                            validator: (v) =>
                                _validateField(v, 'City / Municipality'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _provinceController,
                            label: 'Province',
                            hint: 'Rizal',
                            icon: Icons.map_outlined,
                            readOnly: useSavedAddress,
                            validator: (v) => _validateField(v, 'Province'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _postalController,
                            label: 'Postal Code',
                            hint: '1940',
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            readOnly: useSavedAddress,
                            validator: (v) => _validateField(v, 'Postal code'),
                          ),
                        ),
                      ],
                    ),
                    if (canUseSavedAddress &&
                        !useSavedAddress &&
                        savedProfile != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppColors.tertiaryText,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'This one-off address is only for this order '
                              'and will not replace your saved address.',
                              style: TextStyle(
                                color: AppColors.tertiaryText,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 26),

                    // ===== Payment method (simulated) =====
                    Text(
                      'PAYMENT METHOD (SIMULATED)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.2,
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentOption(
                            title: 'Cash on Delivery',
                            subtitle: 'COD Simulation',
                            icon: Icons.payments_outlined,
                            selected: _paymentMethod == 'COD',
                            onTap: () => setState(() => _paymentMethod = 'COD'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentOption(
                            title: 'GCash',
                            subtitle: 'GCash Simulation',
                            icon: Icons.account_balance_wallet_outlined,
                            selected: _paymentMethod == 'GCash',
                            onTap: () =>
                                setState(() => _paymentMethod = 'GCash'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No real payment will be processed. This is an academic simulation only.',
                      style: TextStyle(
                        color: AppColors.tertiaryText,
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ===== Order summary =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER SUMMARY',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...cart.selectedItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}× ${item.productName} (${item.selectedSize}/${item.selectedColor})',
                                      style: TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₱${item.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 22),
                          _SummaryLine(
                            label: 'Subtotal',
                            value: '₱${_subtotal.toStringAsFixed(2)}',
                          ),
                          _SummaryLine(
                            label: 'Shipping Fee',
                            value: _shippingFee == 0
                                ? 'FREE'
                                : '₱${_shippingFee.toStringAsFixed(2)}',
                            valueColor: _shippingFee == 0
                                ? AppColors.success
                                : AppColors.secondaryText,
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                '₱${_total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ===== Confirm button =====
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder
                            ? null
                            : _requireAuthThenPlaceOrder,
                        child: _isPlacingOrder
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryText,
                                ),
                              )
                            : Text(
                                isGuest
                                    ? 'SIGN IN & CONFIRM ORDER'
                                    : 'CONFIRM ORDER',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'By confirming you agree to the simulated order terms.\nOrders begin as "Pending".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? AppColors.secondaryText : AppColors.primaryText,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19, color: AppColors.secondaryText),
            suffixIcon: readOnly
                ? Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.tertiaryText,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.14)
              : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.primaryAccent
                  : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
