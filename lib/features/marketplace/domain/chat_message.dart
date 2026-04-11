/// CYKEL — Chat domain models

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── ChatMessage ──────────────────────────────────────────────────────────────

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.isRead = false,
    this.imageUrl,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('ChatMessage document ${doc.id} has no data (may have been deleted)');
    }
    final m = data as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: m['senderId'] as String? ?? '',
      senderName: m['senderName'] as String? ?? '',
      text: m['text'] as String? ?? '',
      sentAt: m['sentAt'] is Timestamp
          ? (m['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: m['isRead'] as bool? ?? false,
      imageUrl: m['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

// ─── ChatThread ───────────────────────────────────────────────────────────────

class ChatThread {
  const ChatThread({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ChatThread(
      id: doc.id,
      listingId: m['listingId'] as String? ?? '',
      listingTitle: m['listingTitle'] as String? ?? '',
      listingImageUrl: m['listingImageUrl'] as String?,
      buyerId: m['buyerId'] as String? ?? '',
      buyerName: m['buyerName'] as String? ?? '',
      sellerId: m['sellerId'] as String? ?? '',
      sellerName: m['sellerName'] as String? ?? '',
      lastMessage: m['lastMessage'] as String?,
      lastMessageAt: m['lastMessageAt'] is Timestamp
          ? (m['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCount: m['unreadCount'] as int? ?? 0,
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'listingTitle': listingTitle,
        if (listingImageUrl != null) 'listingImageUrl': listingImageUrl,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'sellerId': sellerId,
        'sellerName': sellerName,
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastMessageAt != null)
          'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
