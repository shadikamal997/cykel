/// CYKEL — Chat Screen
/// Real-time chat conversation with message input

import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/chat_providers.dart';
import '../domain/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _markAsRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markConversationAsRead(ref, widget.conversationId);
    });
  }

  void _onTypingChanged() {
    final text = _messageController.text;
    
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      setTypingIndicator(ref, widget.conversationId, true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        setTypingIndicator(ref, widget.conversationId, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _isTyping = false;
    await setTypingIndicator(ref, widget.conversationId, false);
    
    await sendTextMessage(ref, widget.conversationId, text);
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final typingUsersAsync = ref.watch(typingUsersProvider(widget.conversationId));
    final service = ref.read(chatServiceProvider);
    final currentUserId = service.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/OIUFKE0.webp'),
              fit: BoxFit.cover,
              opacity: 0.15,
            ),
          ),
        ),
        title: conversationAsync.when(
          data: (conversation) {
            if (conversation == null) return const Text('Chat');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.getOtherParticipantName(currentUserId)),
                typingUsersAsync.when(
                  data: (typingUsers) {
                    final othersTyping = typingUsers.where((id) => id != currentUserId).toList();
                    if (othersTyping.isEmpty) return const SizedBox.shrink();
                    return Text(
                      'typing...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, s) => const SizedBox.shrink(),
                ),
              ],
            );
          },
          loading: () => Text(context.l10n.chatLoading),
          error: (error, s) => const Text('Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const _EmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showAvatar = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId;
                    
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: showAvatar,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading messages: $error'),
              ),
            ),
          ),

          // Message input
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttach: () => _showOptionsMenu(context),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text(context.l10n.chatSendPhoto),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 75,
                );
                if (file == null || !mounted) return;
                try {
                  final ref = FirebaseStorage.instance.ref(
                    'chat/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                  await ref.putData(await file.readAsBytes());
                  final url = await ref.getDownloadURL();
                  if (!mounted) return;
                  await sendImageMessage(this.ref, widget.conversationId, url, '');
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send image: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(context.l10n.chatShareLocation),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final perm = await Geolocator.checkPermission();
                  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
                    await Geolocator.requestPermission();
                  }
                  final pos = await Geolocator.getCurrentPosition();
                  if (!mounted) return;
                  await sendLocationMessage(
                    ref,
                    widget.conversationId,
                    pos.latitude,
                    pos.longitude,
                    'My location',
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not get location: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                context.l10n.chatDeleteConversationTitle,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await deleteConversation(ref, widget.conversationId);
                if (!mounted) return;
                navigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  final Message message;
  final bool isMe;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _SystemMessage(message: message);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            AppAvatar(
              url: null,
              size: 32,
              fallbackText: message.senderName.isNotEmpty 
                  ? message.senderName[0].toUpperCase() 
                  : '?',
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image && message.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: message.imageUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  
                  if (message.type == MessageType.location)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Location shared',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ─── System Message ──────────────────────────────────────────────────────────

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message Input ───────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: onAttach,
              color: AppColors.textSecondary,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSend,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Chat ──────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
