/// CYKEL — Chat Service
/// Handles chat messaging and conversation management via Firestore

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? 'Unknown User';

  // ─── Conversations ─────────────────────────────────────────────────────────

  /// Get stream of user's conversations
  Stream<List<Conversation>> getUserConversations() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();
    });
  }

  /// Get single conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .get();

    if (!doc.exists) return null;
    return Conversation.fromFirestore(doc);
  }

  /// Create or get existing direct conversation with another user
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Check if conversation already exists
    final existingQuery = await _firestore
        .collection(_conversationsCollection)
        .where('type', isEqualTo: ConversationType.direct.value)
        .where('participantIds', arrayContains: userId)
        .get();

    for (final doc in existingQuery.docs) {
      final participantIds = (doc.data()['participantIds'] as List<dynamic>).cast<String>();
      if (participantIds.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Get other user's name
    final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
    String otherUserName = 'Unknown';
    if (otherUserDoc.exists) {
      final data = otherUserDoc.data();
      otherUserName = data?['name'] as String? ?? 'Unknown';
    }

    // Create new conversation
    final conversation = Conversation(
      id: '',
      type: ConversationType.direct,
      participantIds: [userId, otherUserId],
      participantNames: {
        userId: currentUserName,
        otherUserId: otherUserName,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_conversationsCollection)
        .add(conversation.toFirestore());

    return docRef.id;
  }

  /// Create group conversation
  Future<String> createGroupConversation({
    required List<String> participantIds,
    required String groupName,
    String? groupImageUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (!participantIds.contains(userId)) {
      participantIds.add(userId);
    }

    // Get participant names
    final participantNames = <String, String>{};
    for (final id in participantIds) {
      final userDoc = await _firestore.collection('users').doc(id).get();
      String userName = 'Unknown';
      if (userDoc.exists) {
        final data = userDoc.data();
        userName = data?['name'] as String? ?? 'Unknown';
      }
      participantNames[id] = userName;
    }

    final conversation = Conversation(
      id: '',
      type: ConversationType.group,
      participantIds: participantIds,
      participantNames: participantNames,
      groupName: groupName,
      groupImageUrl: groupImageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_conversationsCollection)
        .add(conversation.toFirestore());

    // Send system message
    await sendMessage(
      conversationId: docRef.id,
      content: '$currentUserName created the group',
      type: MessageType.system,
    );

    return docRef.id;
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Delete all messages in the conversation
    final messagesQuery = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete conversation
    batch.delete(_firestore.collection(_conversationsCollection).doc(conversationId));

    await batch.commit();
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  /// Get stream of messages in a conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final message = Message(
      id: '',
      conversationId: conversationId,
      senderId: userId,
      senderName: currentUserName,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      readBy: {userId}, // Mark as read by sender
      metadata: metadata,
    );

    // Add message
    await _firestore
        .collection(_messagesCollection)
        .add(message.toFirestore());

    // Update conversation
    final conversation = await getConversation(conversationId);
    if (conversation != null) {
      final updatedUnreadCounts = Map<String, int>.from(conversation.unreadCounts);
      
      // Increment unread count for all participants except sender
      for (final participantId in conversation.participantIds) {
        if (participantId != userId) {
          updatedUnreadCounts[participantId] = (updatedUnreadCounts[participantId] ?? 0) + 1;
        }
      }

      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'lastMessage': content,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'unreadCounts': updatedUnreadCounts,
      });
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Get unread messages
    final messagesQuery = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();

    for (final doc in messagesQuery.docs) {
      final message = Message.fromFirestore(doc);
      if (!message.isReadBy(userId)) {
        final updatedReadBy = Set<String>.from(message.readBy)..add(userId);
        batch.update(doc.reference, {'readBy': updatedReadBy.toList()});
      }
    }

    // Reset unread count for this user
    final conversationRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId);
    
    final conversationDoc = await conversationRef.get();
    if (conversationDoc.exists) {
      final unreadCounts = (conversationDoc.data()?['unreadCounts'] as Map<String, dynamic>?)
              ?.cast<String, int>() ??
          {};
      unreadCounts[userId] = 0;
      batch.update(conversationRef, {'unreadCounts': unreadCounts});
    }

    await batch.commit();
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _firestore
        .collection(_messagesCollection)
        .doc(messageId)
        .delete();
  }

  // ─── Typing Indicators ─────────────────────────────────────────────────────

  /// Set typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }

  /// Get typing users stream
  Stream<List<String>> getTypingUsers(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      return (data?['typingUsers'] as List<dynamic>?)?.cast<String>() ?? [];
    });
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  /// Search conversations by participant name or group name
  Future<List<Conversation>> searchConversations(String query) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .get();

    return snapshot.docs
        .map((doc) => Conversation.fromFirestore(doc))
        .where((conversation) {
      final searchText = query.toLowerCase();
      
      if (conversation.type == ConversationType.group) {
        return conversation.groupName?.toLowerCase().contains(searchText) ?? false;
      } else {
        final otherName = conversation
            .getOtherParticipantName(userId)
            .toLowerCase();
        return otherName.contains(searchText);
      }
    }).toList();
  }
}
