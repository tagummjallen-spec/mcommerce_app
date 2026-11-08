import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(),
      body: isGuest
          ? _buildGuest(context, ref)
          : _buildMember(context, ref, user.uid, profileAsync),
    );
  }

  Widget _buildGuest(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.primaryAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome, Guest',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your profile, view orders,\nand enjoy a personalized experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, height: 1.5),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('LOGIN'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/register'),
                child: const Text('CREATE ACCOUNT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMember(
    BuildContext context,
    WidgetRef ref,
    String uid,
    AsyncValue<UserModel?> profileAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Profile header =====
          profileAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (profile) {
              final name = profile?.displayName ?? 'Customer';
              final email = profile?.email ?? '';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ProfileAvatar(
                      imageUrl: profile?.profileImageUrl ?? '',
                      name: name,
                      radius: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CUSTOMER',
                              style: TextStyle(
                                color: AppColors.lightAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===== Account section =====
          Text(
            'ACCOUNT',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.tertiaryText,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'Order History',
            subtitle: 'View and manage your orders',
            onTap: () => context.push('/profile/orders'),
          ),
          _MenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Personal Info',
            subtitle: 'Update your name, phone, and address',
            onTap: () => context.push('/profile/edit'),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'View updates about orders and more',
            onTap: () => context.push('/profile/notifications'),
          ),
          _MenuTile(
            icon: Icons.support_agent_outlined,
            title: 'Customer Support',
            subtitle: 'Chat with our support team',
            onTap: () => context.push('/support'),
          ),
          _MenuTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () => _showChangePasswordDialog(context, ref),
          ),

          const SizedBox(height: 20),
          Text(
            'SESSION',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.tertiaryText,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: 'Return to the guest home screen',
            iconColor: AppColors.error,
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Ascended Athletics • Academic M-Commerce Demo',
              style: TextStyle(color: AppColors.tertiaryText, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        title: const Text(
          'Log out?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'You will return to the home screen as a guest.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/home');
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondarySurface,
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(hintText: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  hintText: 'New password (min 6 chars)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  hintText: 'Confirm new password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newController.text;
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must be at least 6 characters.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (newPass != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                // Re-authentication is required for recent accounts; the
                // Firebase SDK will throw a specific error we can surface.
                await ref.read(authServiceProvider).changePassword(newPass);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not update password. Try logging in again.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryAccent).withValues(
              alpha: 0.14,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryAccent,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.tertiaryText, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.tertiaryText,
          size: 22,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}
