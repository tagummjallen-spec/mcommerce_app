import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../models/support_message_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/support_chat_provider.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _markedRead = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign in to contact support.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final name = profile?.fullName.trim().isNotEmpty == true
          ? profile!.fullName
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : 'Customer');
      final email = profile?.email ?? user.email ?? '';
      await ref.read(supportChatServiceProvider).sendCustomerMessage(
            userId: user.uid,
            userName: name,
            userEmail: email,
            text: text,
          );
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final messagesAsync = ref.watch(mySupportMessagesProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: const BrandAppBar(
          showBack: true,
          showBag: false,
          title: 'CUSTOMER SUPPORT',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent, size: 56, color: AppColors.primaryAccent),
                const SizedBox(height: 16),
                Text(
                  'Sign in to chat with support',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Our team can help with orders, products, and account questions.',
                  style: TextStyle(color: AppColors.secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/login?redirect=support'),
                  child: const Text('SIGN IN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mark admin replies as read when messages load.
    messagesAsync.whenData((messages) {
      if (!_markedRead) {
        _markedRead = true;
        ref.read(supportChatServiceProvider).markReadByCustomer(user.uid);
      }
      if (messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const BrandAppBar(
        showBack: true,
        showBag: false,
        title: 'CUSTOMER SUPPORT',
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Could not load chat.\n$e',
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.tertiaryText),
                          SizedBox(height: 12),
                          Text(
                            'Start a conversation',
                            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Send a message and our support team will reply here.',
                            style: TextStyle(color: AppColors.secondaryText),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: AppColors.tertiaryText),
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageModel message;
  const _MessageBubble({required this.message});

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isMine = message.senderRole == 'customer';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryAccent : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMine ? const Radius.circular(4) : null,
            bottomLeft: !isMine ? const Radius.circular(4) : null,
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName : 'Support',
                  style: TextStyle(
                    color: AppColors.lightAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.primaryText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMine ? Colors.white70 : AppColors.tertiaryText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
