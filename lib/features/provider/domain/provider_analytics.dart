/// CYKEL — Provider Analytics Domain Model
/// Tracks profile views, navigation requests, and saved-by-users count.

import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderAnalytics {
  const ProviderAnalytics({
    required this.providerId,
    required this.userId,
    this.profileViews = 0,
    this.navigationRequests = 0,
    this.savedByUsersCount = 0,
    this.lastUpdated,
  });

  final String providerId;
  final String userId;
  final int profileViews;
  final int navigationRequests;
  final int savedByUsersCount;
  final DateTime? lastUpdated;

  factory ProviderAnalytics.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ProviderAnalytics(
      providerId: doc.id,
      userId: m['userId'] as String? ?? '',
      profileViews: m['profileViews'] as int? ?? 0,
      navigationRequests: m['navigationRequests'] as int? ?? 0,
      savedByUsersCount: m['savedByUsersCount'] as int? ?? 0,
      lastUpdated: m['lastUpdated'] is Timestamp
          ? (m['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'profileViews': profileViews,
        'navigationRequests': navigationRequests,
        'savedByUsersCount': savedByUsersCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  ProviderAnalytics copyWith({
    String? providerId,
    String? userId,
    int? profileViews,
    int? navigationRequests,
    int? savedByUsersCount,
    DateTime? lastUpdated,
  }) =>
      ProviderAnalytics(
        providerId: providerId ?? this.providerId,
        userId: userId ?? this.userId,
        profileViews: profileViews ?? this.profileViews,
        navigationRequests: navigationRequests ?? this.navigationRequests,
        savedByUsersCount: savedByUsersCount ?? this.savedByUsersCount,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
