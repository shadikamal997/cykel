/// CYKEL — Chat Screen (in-app messaging per listing)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/optimized_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/chat_service.dart';
import '../data/marketplace_service.dart';
import '../domain/chat_message.dart';
import '../providers/marketplace_providers.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryText = Color(0xFF1A1A1A);
const _kSecondaryText = Color(0xFF6B6B6B);
const _kBackground = Color(0xFFFFFFFF);
const _kSoftElements = Color(0xFFE9ECE6);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.threadId, this.thread});

  final String threadId;
  final ChatThread? thread; // pre-loaded via GoRouter extra

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _loadingMore = false;
  String? _lastMessageId;
  bool _shouldAutoScroll = true;
  
  // Pagination state
  final List<ChatMessage> _olderMessages = [];
  DocumentSnapshot? _oldestSnapshot;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    // Mark thread as read when opened
    Future.microtask(() =>
        ref.read(chatServiceProvider).markRead(widget.threadId));
    
    // Listen for scroll to detect manual scrolling
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    // Disable auto-scroll if user manually scrolls up
    if (_scrollCtrl.hasClients) {
      final atBottom = _scrollCtrl.position.pixels >= 
          _scrollCtrl.position.maxScrollExtent - 50;
      if (_shouldAutoScroll != atBottom) {
        setState(() => _shouldAutoScroll = atBottom);
      }
      
      // Load more messages when scrolling near top
      if (_scrollCtrl.position.pixels <= 200 && !_loadingMore) {
        _loadOlderMessages();
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || !_hasMoreMessages || _oldestSnapshot == null) return;
    _loadingMore = true;
    if (mounted) setState(() {});
    
    try {
      final chatService = ref.read(chatServiceProvider);
      final olderMsgs = await chatService.loadOlderMessages(
        widget.threadId,
        _oldestSnapshot!,
        limit: 50,
      );
      
      if (!mounted) return;
      
      if (olderMsgs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _loadingMore = false;
        });
        return;
      }
      
      // Get the new oldest snapshot for next pagination
      final db = FirebaseFirestore.instance;
      final oldestDoc = await db
          .collection('marketplace_chats')
          .doc(widget.threadId)
          .collection('messages')
          .doc(olderMsgs.first.id)
          .get();
      
      if (!mounted) return;
      
      setState(() {
        _olderMessages.insertAll(0, olderMsgs);
        _oldestSnapshot = oldestDoc;
        _loadingMore = false;
        _hasMoreMessages = olderMsgs.length >= 50;
      });
    } catch (e) {
      debugPrint('Error loading older messages: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }
  
  // Get the oldest snapshot from current stream messages
  Future<void> _updateOldestSnapshot(List<ChatMessage> messages) async {
    if (messages.isEmpty || _oldestSnapshot != null) return;
    
    try {
      final db = FirebaseFirestore.instance;
      final oldestDoc = await db
          .collection('marketplace_chats')
          .doc(widget.threadId)
          .collection('messages')
          .doc(messages.first.id)
          .get();
      
      setState(() {
        _oldestSnapshot = oldestDoc;
      });
    } catch (e) {
      debugPrint('Error getting oldest snapshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.threadId));
    final thread = widget.thread;

    if (thread == null) {
      return Scaffold(
        backgroundColor: _kBackground,
        appBar: AppBar(
          backgroundColor: _kBackground,
          leading: IconButton(
            tooltip: 'Go back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.chatTitle),
        ),
        body: Center(
          child: Text(l10n.chatThreadNotFound),
        ),
      );
    }

    // Determine current user's role
    final isSeller = user?.uid == thread.sellerId;
    final otherName = isSeller ? thread.buyerName : thread.sellerName;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        leading: IconButton(
          tooltip: 'Go back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName,
                style: AppTextStyles.headline3.copyWith(fontSize: 15)),
            if (thread.listingTitle.isNotEmpty)
              Text(thread.listingTitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: _kSecondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          if (isSeller)
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: const Color(0xFFF8F9FA),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'sold',
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 22,
                        color: Color(0xFF4A5568),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        l10n.listingMarkSold,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (v) async {
                if (v == 'sold') {
                  await ref
                      .read(marketplaceServiceProvider)
                      .markSold(thread.listingId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.listingMarkedSold)));
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Listing preview
          _ListingBanner(thread: thread),

          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (messages) {
                if (messages.isEmpty && _olderMessages.isEmpty) {
                  return Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 52, color: _kSoftElements),
                      const SizedBox(height: 12),
                      Text(l10n.chatSend,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: _kSecondaryText)),
                    ],
                  ));
                }
                
                // Initialize oldest snapshot on first load
                if (messages.isNotEmpty && _oldestSnapshot == null) {
                  _updateOldestSnapshot(messages);
                }
                
                // Merge older messages with current stream
                final allMessages = [..._olderMessages, ...messages];
                
                // Auto-scroll to bottom on new messages (if enabled)
                if (messages.isNotEmpty) {
                  final latestId = messages.last.id;
                  if (latestId != _lastMessageId && _shouldAutoScroll) {
                    _lastMessageId = latestId;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollCtrl.hasClients) {
                        _scrollCtrl.animateTo(
                          _scrollCtrl.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    });
                  }
                }
                
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: allMessages.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    // Show loading indicator at top while loading more
                    if (_loadingMore && i == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final msgIndex = _loadingMore ? i - 1 : i;
                    final msg = allMessages[msgIndex];
                    final isMe = msg.senderId == user?.uid;
                    final showDate = msgIndex == 0 ||
                        !_sameDay(
                            allMessages[msgIndex - 1].sentAt, msg.sentAt);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDate)
                            _DateDivider(msg.sentAt),
                          _Bubble(
                              message: msg, isMe: isMe),
                        ]);
                  },
                );
              },
            ),
          ),

          // Input bar
          _InputBar(
            controller: _textCtrl,
            sending: _sending,
            onSend: () => _sendMessage(user?.uid, user?.displayName),
            onImage: () => _sendImage(user?.uid, user?.displayName),
            hint: l10n.chatMessageHint,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String? uid, String? displayName) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(chatServiceProvider).sendMessage(
            tId: widget.threadId,
            message: ChatMessage(
              id: '',
              senderId: uid,
              senderName: displayName ?? 'User',
              text: text,
              sentAt: DateTime.now(),
            ),
          );
      _textCtrl.clear();
      // Scroll to bottom after send
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.failedToSendMessage(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _sendImage(String? uid, String? displayName) async {
    if (uid == null || _sending) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final chatSvc = ref.read(chatServiceProvider);
      final url = await chatSvc.uploadChatImage(widget.threadId, picked);
      await chatSvc.sendMessage(
        tId: widget.threadId,
        message: ChatMessage(
          id: '',
          senderId: uid,
          senderName: displayName ?? 'User',
          text: '',
          sentAt: DateTime.now(),
          imageUrl: url,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.failedToSendMessage(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ─── Listing Banner ───────────────────────────────────────────────────────────

class _ListingBanner extends StatelessWidget {
  const _ListingBanner({required this.thread});
  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: _kBackground,
          border: Border(
              bottom: BorderSide(
                  color: _kSoftElements, width: 1)),
        ),
        child: Row(children: [
          if (thread.listingImageUrl != null)
            OptimizedNetworkImage(
              imageUrl: thread.listingImageUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
              errorWidget: const SizedBox(width: 44, height: 44),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.pedal_bike_rounded,
                  color: isDark ? Colors.white : Colors.black, size: 22),
            ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(thread.listingTitle,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? (isDark ? Colors.white : Colors.black) : _kBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(message.senderName,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600)),
              ),
            if (message.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: _kSecondaryText),
                ),
              ),
            if (message.text.isNotEmpty)
              Text(message.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe
                          ? Colors.white
                          : _kPrimaryText)),
            const SizedBox(height: 2),
            Text(DateFormat('HH:mm').format(message.sentAt),
                style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : _kSecondaryText)),
          ],
        ),
      ),
    );
  }
}

// ─── Date Divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider(this.date);
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Use UTC to avoid timezone issues with date comparisons
    final nowUtc = DateTime.now().toUtc();
    final todayUtc = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);
    final dateUtc = date.toUtc();
    final msgDayUtc = DateTime(dateUtc.year, dateUtc.month, dateUtc.day);
    final diff = todayUtc.difference(msgDayUtc).inDays;
    
    String label;
    final l10n = context.l10n;
    if (diff == 0) {
      label = l10n.today;
    } else if (diff == 1) {
      label = l10n.yesterday;
    } else {
      label = DateFormat('d MMM').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(
            child: Divider(color: _kSoftElements)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: _kSecondaryText)),
        ),
        const Expanded(
            child: Divider(color: _kSoftElements)),
      ]),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onImage,
    required this.hint,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        padding: EdgeInsets.fromLTRB(
            12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
        decoration: const BoxDecoration(
          color: _kBackground,
          border: Border(
              top: BorderSide(
                  color: _kSoftElements, width: 1)),
        ),
        child: Row(children: [
          // Image attach button
          GestureDetector(
            onTap: sending ? null : onImage,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.image_rounded,
                  color: sending
                      ? _kSecondaryText
                      : _kSecondaryText,
                  size: 24),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: _kSoftElements, width: 1),
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: _kSecondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: sending
                      ? _kSoftElements
                      : (isDark ? Colors.white : Colors.black),
                  shape: BoxShape.circle),
              child: sending
                  ? const Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ]),
      );
  }
}
