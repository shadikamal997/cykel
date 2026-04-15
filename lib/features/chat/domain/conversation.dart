/// CYKEL — Conversation Domain Model
/// Represents a chat conversation between users

import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType {
  direct,
  group,
  support;

  String get value {
    switch (this) {
      case ConversationType.direct:
        return 'direct';
      case ConversationType.group:
        return 'group';
      case ConversationType.support:
        return 'support';
    }
  }

  static ConversationType fromString(String value) {
    return ConversationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConversationType.direct,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts = const {},
    this.groupName,
    this.groupImageUrl,
    this.metadata,
  });

  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  final String? groupName;
  final String? groupImageUrl;
  final Map<String, dynamic>? metadata;

  bool hasParticipant(String userId) => participantIds.contains(userId);

  int unreadCountFor(String userId) => unreadCounts[userId] ?? 0;

  String getOtherParticipantName(String currentUserId) {
    if (type == ConversationType.group) {
      return groupName ?? 'Group Chat';
    }
    
    final otherParticipantId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    return participantNames[otherParticipantId] ?? 'Unknown';
  }

  String? getOtherParticipantId(String currentUserId) {
    if (type == ConversationType.group) {
      return null;
    }
    
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Conversation copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    String? groupName,
    String? groupImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Conversation(
      id: doc.id,
      type: ConversationType.fromString(data['type'] as String),
      participantIds: (data['participantIds'] as List<dynamic>).cast<String>(),
      participantNames: (data['participantNames'] as Map<String, dynamic>).cast<String, String>(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCounts: (data['unreadCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      groupName: data['groupName'] as String?,
      groupImageUrl: data['groupImageUrl'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': Timestamp.fromDate(lastMessageTime!),
      'unreadCounts': unreadCounts,
      if (groupName != null) 'groupName': groupName,
      if (groupImageUrl != null) 'groupImageUrl': groupImageUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
