import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/support_chat_provider.dart';
import '../../profile/widgets/profile_avatar.dart';

/// Persistent, draggable customer-support chathead that floats above the main
/// tab UI. Tapping it opens the live support conversation.
class SupportChatHead extends ConsumerStatefulWidget {
  const SupportChatHead({super.key});

  @override
  ConsumerState<SupportChatHead> createState() => _SupportChatHeadState();
}

class _SupportChatHeadState extends ConsumerState<SupportChatHead> {
  static const double _size = 58;

  double _right = 16;
  double _bottom = 18;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final unread = ref.watch(supportUnreadByCustomerProvider);
    final screen = MediaQuery.sizeOf(context);

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
          setState(() {
            _right = (_right - details.delta.dx).clamp(
              8.0,
              (screen.width - _size - 8).clamp(8.0, double.infinity),
            );
            _bottom = (_bottom - details.delta.dy).clamp(
              8.0,
              (screen.height - _size - 150).clamp(8.0, double.infinity),
            );
          });
        },
        onPanEnd: (_) => setState(() => _dragging = false),
        onTap: () => context.push('/support'),
        child: Tooltip(
          message: 'Chat with support',
          child: AnimatedScale(
            scale: _dragging ? 1.08 : 1,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: _size,
              height: _size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryAccent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryText.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: profile != null
                        ? ProfileAvatar(
                            imageUrl: profile.profileImageUrl,
                            name: profile.displayName,
                            radius: (_size - 10) / 2,
                            backgroundColor: AppColors.softGreen,
                          )
                        : const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.headset_mic_rounded,
                              color: AppColors.onAccent,
                              size: 26,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondarySurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondarySurface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
