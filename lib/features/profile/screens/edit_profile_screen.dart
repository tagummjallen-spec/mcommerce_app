import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();

  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _prefilledFromProfile = false;
  bool _prefilledFromAuth = false;
  String _profileImageUrl = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    super.dispose();
  }

  void _applyProfile(UserModel? profile, User? user) {
    if (profile != null) {
      if (_prefilledFromProfile) return;
      _prefilledFromProfile = true;
      // Defer controller updates until after this frame; writing to a
      // TextEditingController during build notifies listeners that rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _nameController.text = profile.displayName;
          _phoneController.text = profile.phoneNumber;
          _emailController.text = profile.email;
          _streetController.text = profile.streetAddress;
          _barangayController.text = profile.barangay;
          _profileImageUrl = profile.profileImageUrl;
        });
      });
      return;
    }

    if (user != null && !_prefilledFromAuth) {
      _prefilledFromAuth = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = user.displayName ?? '';
          }
          _emailController.text = user.email ?? '';
        });
      });
    }
  }

  /// Mirrors the admin dashboard's product-image pipeline: pick an image,
  /// downscale/compress it to a JPEG data URL under 100KB and store that
  /// string on the user document (this project uses no Firebase Storage bucket).
  Future<String> _compressToDataUrl(Uint8List originalBytes) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception('Could not decode the selected image.');
    }

    var current = decoded;
    if (current.width > 400 || current.height > 400) {
      current = img.copyResize(
        current,
        width: current.width >= current.height ? 400 : null,
        height: current.height > current.width ? 400 : null,
        interpolation: img.Interpolation.linear,
      );
    }

    var quality = 62;
    var jpgBytes = Uint8List.fromList(
      img.encodeJpg(current, quality: quality),
    );

    while (jpgBytes.lengthInBytes > 100 * 1024) {
      final nextWidth = (current.width * 0.8).round();
      final nextHeight = (current.height * 0.8).round();
      if (nextWidth < 60 || nextHeight < 60) {
        while (jpgBytes.lengthInBytes > 100 * 1024 && quality > 20) {
          quality -= 10;
          jpgBytes = Uint8List.fromList(
            img.encodeJpg(current, quality: quality),
          );
        }
        break;
      }
      current = img.copyResize(
        current,
        width: nextWidth,
        height: nextHeight,
        interpolation: img.Interpolation.linear,
      );
      quality = quality > 30 ? quality - 10 : 30;
      jpgBytes = Uint8List.fromList(
        img.encodeJpg(current, quality: quality),
      );
    }

    return 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';
  }

  Future<void> _pickPhoto() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 92,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('The selected image is empty.');
      }
      final dataUrl = await _compressToDataUrl(bytes);
      if (!mounted) return;
      setState(() => _profileImageUrl = dataUrl);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not update photo: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removePhoto() {
    if (_profileImageUrl.isEmpty) return;
    setState(() => _profileImageUrl = '');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      _showSnack('Please sign in to update your profile.', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateUserProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        streetAddress: _streetController.text.trim(),
        barangay: _barangayController.text.trim(),
        profileImageUrl: _profileImageUrl,
      );
      // The profile provider is a Firestore stream, but invalidating guarantees
      // an immediate refresh on all listeners (chathead, checkout, profile).
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      _showSnack('Profile updated.', AppColors.success);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Update failed: ${e.toString().replaceFirst('Exception: ', '')}',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    _applyProfile(profileAsync.valueOrNull, user);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(showBack: true),
      body: user == null
          ? _SignInGate(onSignIn: () => context.push('/login'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Avatar =====
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            imageUrl: _profileImageUrl,
                            name: _nameController.text,
                            radius: 58,
                          ),
                          Positioned(
                            right: -2,
                            bottom: 2,
                            child: GestureDetector(
                              onTap: _isPickingImage ? null : _pickPhoto,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.secondarySurface,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryText.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _isPickingImage
                                    ? Padding(
                                        padding: EdgeInsets.all(9),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onAccent,
                                        ),
                                      )
                                    : Icon(
                                        Icons.photo_camera_rounded,
                                        color: AppColors.onAccent,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isPickingImage ? null : _pickPhoto,
                          icon: const Icon(Icons.photo_library_outlined, size: 17),
                          label: const Text('Change photo'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _profileImageUrl.isEmpty
                              ? null
                              : _removePhoto,
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ===== Personal details =====
                    const _SectionLabel('Personal details'),
                    const SizedBox(height: 6),
                    _UnderlinedField(
                      label: 'Display name',
                      child: TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Display name is required';
                          if (value.length < 2) return 'Enter a valid name';
                          return null;
                        },
                        decoration: _underlineDecoration(
                          hint: 'Juan Dela Cruz',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedField(
                      label: 'Phone number',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Phone number is required';
                          return null;
                        },
                        decoration: _underlineDecoration(
                          hint: '09XX XXX XXXX',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedField(
                      label: 'Email address',
                      child: TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        enabled: false,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 15,
                        ),
                        decoration: _underlineDecoration(
                          hint: 'you@example.com',
                          suffixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.tertiaryText,
                          ),
                          helper: 'Email address cannot be changed. Please '
                              'contact support if you need to update it.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ===== Delivery address =====
                    const _SectionLabel('Delivery address'),
                    const SizedBox(height: 6),
                    _UnderlinedField(
                      label: 'Street address / House no.',
                      child: TextFormField(
                        controller: _streetController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _underlineDecoration(
                          hint: 'Blk 12 Lot 3, Sampaguita St.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedField(
                      label: 'Barangay / City',
                      child: TextFormField(
                        controller: _barangayController,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _underlineDecoration(
                          hint: 'Barangay San Isidro, Binangonan',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.tertiaryText,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Clearing both fields removes your saved delivery '
                            'address. Checkout will then ask for it again.',
                            style: TextStyle(
                              color: AppColors.tertiaryText,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onAccent,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _underlineDecoration({
    required String hint,
    Widget? suffixIcon,
    String? helper,
  }) {
    final underline = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.borderLight),
    );
    return InputDecoration(
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      filled: false,
      isDense: true,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 32),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      hintStyle: TextStyle(color: AppColors.tertiaryText, fontSize: 15),
      helperStyle: TextStyle(
        color: AppColors.tertiaryText,
        fontSize: 11.5,
        height: 1.35,
      ),
      border: underline,
      enabledBorder: underline,
      disabledBorder: underline,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _UnderlinedField extends StatelessWidget {
  final String label;
  final Widget child;

  const _UnderlinedField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.tertiaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

class _SignInGate extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInGate({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 44,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to edit your profile',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved delivery details are tied to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSignIn,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
