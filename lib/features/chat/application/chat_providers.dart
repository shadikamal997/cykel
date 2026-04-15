/// CYKEL — Chat Providers
/// Riverpod providers for chat state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'chat_service.dart';

// ─── Service Provider ────────────────────────────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// ─── Conversation Providers ──────────────────────────────────────────────────

/// Stream of user's conversations
final conversationsProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.getUserConversations();
});

/// Get single conversation by ID
final conversationProvider = FutureProvider.autoDispose.family<Conversation?, String>(
  (ref, conversationId) async {
    final service = ref.watch(chatServiceProvider);
    return await service.getConversation(conversationId);
  },
);

/// Search conversations
final searchConversationsProvider = FutureProvider.autoDispose.family<List<Conversation>, String>(
  (ref, query) async {
    final service = ref.watch(chatServiceProvider);
    if (query.isEmpty) {
      return [];
    }
    return await service.searchConversations(query);
  },
);

// ─── Message Providers ───────────────────────────────────────────────────────

/// Stream of messages in a conversation
final messagesProvider = StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, conversationId) {
    final service = ref.watch(chatServiceProvider);
    return service.getMessages(conversationId);
  },
);

/// Typing users in a conversation
final typingUsersProvider = StreamProvider.autoDispose.family<List<String>, String>(
  (ref, conversationId) {
    final service = ref.watch(chatServiceProvider);
    return service.getTypingUsers(conversationId);
  },
);

// ─── State Providers ─────────────────────────────────────────────────────────

/// Currently active conversation
final activeConversationProvider = StateProvider<String?>((ref) => null);

/// Message input text
final messageInputProvider = StateProvider.autoDispose<String>((ref) => '');

/// Is user typing
final isTypingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Selected conversation for actions
final selectedConversationProvider = StateProvider<Conversation?>((ref) => null);

/// Search query
final conversationSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Statistics ──────────────────────────────────────────────────────────────

/// Total unread messages count
final totalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  final service = ref.watch(chatServiceProvider);
  final userId = service.currentUserId;

  if (userId == null) return 0;

  return conversationsAsync.when(
    data: (conversations) => conversations.fold<int>(
      0,
      (total, conv) => total + conv.unreadCountFor(userId),
    ),
    loading: () => 0,
    error: (error, s) => 0,
  );
});

/// Count of active conversations
final activeConversationsCountProvider = Provider.autoDispose<int>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);

  return conversationsAsync.when(
    data: (conversations) => conversations.length,
    loading: () => 0,
    error: (error, s) => 0,
  );
});

/// Conversations with unread messages
final unreadConversationsProvider = Provider.autoDispose<AsyncValue<List<Conversation>>>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  final service = ref.watch(chatServiceProvider);
  final userId = service.currentUserId;

  if (userId == null) {
    return const AsyncValue.data([]);
  }

  return conversationsAsync.whenData((conversations) {
    return conversations
        .where((conv) => conv.unreadCountFor(userId) > 0)
        .toList();
  });
});

// ─── Actions ─────────────────────────────────────────────────────────────────

/// Send a text message
Future<void> sendTextMessage(
  WidgetRef ref,
  String conversationId,
  String content,
) async {
  final service = ref.read(chatServiceProvider);
  await service.sendMessage(
    conversationId: conversationId,
    content: content,
    type: MessageType.text,
  );
}

/// Send an image message
Future<void> sendImageMessage(
  WidgetRef ref,
  String conversationId,
  String imageUrl,
  String caption,
) async {
  final service = ref.read(chatServiceProvider);
  await service.sendMessage(
    conversationId: conversationId,
    content: caption,
    type: MessageType.image,
    imageUrl: imageUrl,
  );
}

/// Send a location message
Future<void> sendLocationMessage(
  WidgetRef ref,
  String conversationId,
  double latitude,
  double longitude,
  String description,
) async {
  final service = ref.read(chatServiceProvider);
  await service.sendMessage(
    conversationId: conversationId,
    content: description,
    type: MessageType.location,
    latitude: latitude,
    longitude: longitude,
  );
}

/// Mark conversation as read
Future<void> markConversationAsRead(
  WidgetRef ref,
  String conversationId,
) async {
  final service = ref.read(chatServiceProvider);
  await service.markMessagesAsRead(conversationId);
}

/// Delete conversation
Future<void> deleteConversation(
  WidgetRef ref,
  String conversationId,
) async {
  final service = ref.read(chatServiceProvider);
  await service.deleteConversation(conversationId);
}

/// Create direct conversation
Future<String> createDirectConversation(
  WidgetRef ref,
  String otherUserId,
) async {
  final service = ref.read(chatServiceProvider);
  return await service.getOrCreateDirectConversation(otherUserId);
}

/// Create group conversation
Future<String> createGroupConversation(
  WidgetRef ref, {
  required List<String> participantIds,
  required String groupName,
  String? groupImageUrl,
}) async {
  final service = ref.read(chatServiceProvider);
  return await service.createGroupConversation(
    participantIds: participantIds,
    groupName: groupName,
    groupImageUrl: groupImageUrl,
  );
}

/// Set typing indicator
Future<void> setTypingIndicator(
  WidgetRef ref,
  String conversationId,
  bool isTyping,
) async {
  final service = ref.read(chatServiceProvider);
  await service.setTyping(conversationId, isTyping);
}
