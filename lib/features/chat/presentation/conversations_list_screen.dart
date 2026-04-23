/// CYKEL — Conversations List Screen
/// Shows all user's chat conversations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
import '../application/chat_providers.dart';
import '../domain/conversation.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onConversationTap(Conversation conversation) {
    ref.read(activeConversationProvider.notifier).state = conversation.id;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conversation.id),
      ),
    );
  }

  Future<void> _onDeleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chatDeleteConversation),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteConversation(ref, conversation.id);
    }
  }

  void _showNewMessageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewMessageSheet(
        onUserSelected: (userId) async {
          final service = ref.read(chatServiceProvider);
          final conversationId = await service.getOrCreateDirectConversation(userId);
          if (!mounted) return;
          if (context.mounted) Navigator.pop(context);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversationId: conversationId),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final searchQuery = ref.watch(conversationSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.chatMessages),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () => _showNewMessageSheet(context),
            tooltip: 'New Message',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(conversationSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (value) {
                ref.read(conversationSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Conversations list
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                // Filter by search query
                final filteredConversations = searchQuery.isEmpty
                    ? conversations
                    : conversations.where((conv) {
                        final service = ref.read(chatServiceProvider);
                        final userId = service.currentUserId ?? '';
                        final name = conv.getOtherParticipantName(userId).toLowerCase();
                        return name.contains(searchQuery.toLowerCase());
                      }).toList();

                if (filteredConversations.isEmpty) {
                  return _EmptyState(
                    isSearching: searchQuery.isNotEmpty,
                  );
                }

                return ListView.builder(
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    return RepaintBoundary(
                      child: _ConversationTile(
                        conversation: conversation,
                        onTap: () => _onConversationTap(conversation),
                        onDelete: () => _onDeleteConversation(conversation),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    const Text('Error loading conversations', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    Text(error.toString(), style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation Tile ───────────────────────────────────────────────────────

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(chatServiceProvider);
    final userId = service.currentUserId ?? '';
    final unreadCount = conversation.unreadCountFor(userId);
    final hasUnread = unreadCount > 0;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: ListTile(
        leading: _Avatar(conversation: conversation),
        title: Text(
          conversation.getOtherParticipantName(userId),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: conversation.lastMessage != null
            ? Text(
                conversation.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageTime != null)
              Text(
                _formatTime(conversation.lastMessageTime!),
                style: AppTextStyles.caption.copyWith(
                  color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _Avatar extends ConsumerWidget {
  const _Avatar({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(chatServiceProvider);
    final userId = service.currentUserId ?? '';
    final name = conversation.getOtherParticipantName(userId);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (conversation.type == ConversationType.group &&
        conversation.groupImageUrl != null) {
      return AppAvatar(
        url: conversation.groupImageUrl,
        thumbnailUrl: AppUser.getThumbnailUrl(conversation.groupImageUrl),
        size: 48,
        fallbackText: '👥',
      );
    }

    return AppAvatar(
      url: null,
      size: 48,
      fallbackText: conversation.type == ConversationType.group ? '👥' : initial,
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No conversations found' : 'No messages yet',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Start a conversation with other riders',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── New Message Sheet ────────────────────────────────────────────────────────

class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet({required this.onUserSelected});
  final Future<void> Function(String userId) onUserSelected;

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(15)
          .get();
      if (mounted) {
        setState(() => _results = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('New Message', style: AppTextStyles.labelLarge),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 8),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Type a name to search for riders'
                            : 'No riders found',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final user = _results[i];
                        return ListTile(
                          leading: AppAvatar(
                            url: user['photoUrl'] as String?,
                            size: 40,
                            fallbackText: (user['displayName'] as String? ?? '?')[0].toUpperCase(),
                          ),
                          title: Text(user['displayName'] as String? ?? 'Rider'),
                          subtitle: Text(user['email'] as String? ?? ''),
                          onTap: () => widget.onUserSelected(user['id'] as String),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
