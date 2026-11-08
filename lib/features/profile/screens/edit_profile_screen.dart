import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefill(UserModel? profile, User? user) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = profile?.fullName ?? user?.displayName ?? '';
    _phoneController.text = profile?.phone ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      await user.updateDisplayName(_nameController.text.trim());
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    profileAsync.whenData((profile) => _prefill(profile, user));
    if (user != null) _prefill(null, user);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(title: const Text('EDIT PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only email note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: AppColors.secondaryText, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: AppColors.secondaryText, fontSize: 13.5),
                      ),
                    ),
                    const Text('Verified',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('FULL NAME',
                  style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.primaryText),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 2) return 'Enter a valid name';
                  return null;
                },
                decoration: const InputDecoration(hintText: 'Juan Dela Cruz'),
              ),
              const SizedBox(height: 18),
              const Text('PHONE NUMBER',
                  style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.primaryText),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(hintText: '09XX XXX XXXX'),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryText),
                        )
                      : const Text('SAVE CHANGES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
