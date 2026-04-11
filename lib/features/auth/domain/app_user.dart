/// Domain model for an authenticated CYKEL user.
/// Maps Firestore `users/{uid}` document + Firebase Auth user.

import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.emailVerified,
    this.photoUrl,
    this.phone,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role; // rider | provider_personal | provider_business | admin
  final bool emailVerified;
  final String? photoUrl;
  final String? phone;
  final DateTime? createdAt;

  bool get isRider => role == 'rider';
  bool get isProvider =>
      role == 'provider_personal' || role == 'provider_business';
  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: map['role'] as String? ?? 'rider',
      emailVerified: map['emailVerified'] as bool? ?? false,
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'emailVerified': emailVerified,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    bool? emailVerified,
    String? photoUrl,
    String? phone,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
