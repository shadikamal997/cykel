/// CYKEL — Message Domain Model
/// Represents a single chat message

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  location,
  system;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.location:
        return 'location';
      case MessageType.system:
        return 'system';
    }
  }

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.readBy = const {},
    this.metadata,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final Set<String> readBy;
  final Map<String, dynamic>? metadata;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool get isSystemMessage => type == MessageType.system;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? imageUrl,
    double? latitude,
    double? longitude,
    Set<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      content: data['content'] as String,
      type: MessageType.fromString(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
      readBy: (data['readBy'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'readBy': readBy.toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
