/// CYKEL — Chat Firestore service

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/input_validator.dart';
import '../domain/chat_message.dart';

class ChatService {
  ChatService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _threads =>
      _db.collection('marketplace_chats');

  static String threadId(String listingId, String buyerId) =>
      '${listingId}_$buyerId';

  // ── Threads ────────────────────────────────────────────────────────────────

  Stream<List<ChatThread>> streamThreads(String uid) => _threads
      .where(Filter.or(
        Filter('buyerId', isEqualTo: uid),
        Filter('sellerId', isEqualTo: uid),
      ))
      .snapshots()
      .map((s) {
        final list = s.docs.map(ChatThread.fromFirestore).toList();
        list.sort((a, b) {
          final ta = a.lastMessageAt ?? a.createdAt;
          final tb = b.lastMessageAt ?? b.createdAt;
          return tb.compareTo(ta);
        });
        return list;
      });

  Future<ChatThread> getOrCreateThread({
    required String listingId,
    required String listingTitle,
    String? listingImageUrl,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) async {
    try {
      final id = threadId(listingId, buyerId);
      final doc = await _threads.doc(id).get();
      if (doc.exists) return ChatThread.fromFirestore(doc);
      final thread = ChatThread(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        listingImageUrl: listingImageUrl,
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: sellerId,
        sellerName: sellerName,
        createdAt: DateTime.now(),
      );
      await _threads.doc(id).set(thread.toMap());
      return thread;
    } catch (e) {
      throw Exception('Failed to create chat thread: $e');
    }
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> streamMessages(String tId) => _threads
      .doc(tId)
      .collection('messages')
      .orderBy('sentAt', descending: false)
      .limitToLast(100)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());

  /// Load older messages for pagination (ordered oldest-first for proper display)
  Future<List<ChatMessage>> loadOlderMessages(
    String tId,
    DocumentSnapshot lastDoc, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _threads
          .doc(tId)
          .collection('messages')
          .orderBy('sentAt', descending: true) // Get older messages
          .startAfterDocument(lastDoc)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(ChatMessage.fromFirestore)
          .toList()
          .reversed // Reverse to get oldest-first for display
          .toList();
    } catch (e) {
      debugPrint('Error loading older messages: $e');
      return [];
    }
  }

  Future<void> sendMessage(
      {required String tId, required ChatMessage message}) async {
    try {
      // Sanitize message text to prevent XSS attacks
      final sanitizedText = InputValidator.sanitize(message.text);
      final sanitizedMessage = ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        text: sanitizedText,
        sentAt: message.sentAt,
        isRead: message.isRead,
        imageUrl: message.imageUrl,
      );
      
      final batch = _db.batch();
      final msgRef = _threads.doc(tId).collection('messages').doc();
      batch.set(msgRef, sanitizedMessage.toMap());
      batch.update(_threads.doc(tId), {
        'lastMessage': message.isImage ? '📷 Photo' : sanitizedText,
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        'unreadCount': FieldValue.increment(1),
      });
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markRead(String tId) async {
    try {
      await _threads.doc(tId).update({'unreadCount': 0});
    } catch (_) {
      // Silently ignore — non-critical operation
    }
  }

  /// Count of chat threads for a specific listing (seller perspective).
  Stream<int> streamInquiriesCount(String listingId) => _threads
      .where('listingId', isEqualTo: listingId)
      .snapshots()
      .map((s) => s.docs.length);

  /// Upload an image for chat and return its download URL.
  Future<String> uploadChatImage(String threadId, XFile file) async {
    final ref = _storage
        .ref()
        .child('marketplace_chats/$threadId/'
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await ref.putFile(
      File(file.path),
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }
}

final chatServiceProvider =
    Provider<ChatService>((ref) => ChatService(
        FirebaseFirestore.instance, FirebaseStorage.instance));
