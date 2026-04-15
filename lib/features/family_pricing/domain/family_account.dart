import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of a member within a family account
enum FamilyRole {
  owner,
  admin,
  member,
  child;

  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Owner';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.member:
        return 'Member';
      case FamilyRole.child:
        return 'Child';
    }
  }

  bool get canManageMembers =>
      this == FamilyRole.owner || this == FamilyRole.admin;

  bool get canManageBilling => this == FamilyRole.owner;
}

/// Invitation status for family member invites
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  revoked;

  bool get isActive => this == InvitationStatus.pending;
}

/// A family account that groups users under a shared subscription
class FamilyAccount {
  final String id;
  final String name;
  final String ownerId;
  final String subscriptionId;
  final List<FamilyMember> members;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? familyPhotoUrl;

  const FamilyAccount({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.subscriptionId,
    required this.members,
    required this.maxMembers,
    required this.createdAt,
    this.updatedAt,
    this.familyPhotoUrl,
  });

  int get memberCount => members.length;
  bool get isFull => members.length >= maxMembers;
  int get availableSlots => maxMembers - members.length;

  FamilyMember? get owner =>
      members.where((m) => m.role == FamilyRole.owner).firstOrNull;

  List<FamilyMember> get activeMembers =>
      members.where((m) => m.isActive).toList();

  List<FamilyMember> get childMembers =>
      members.where((m) => m.role == FamilyRole.child).toList();

  bool isMember(String userId) =>
      members.any((m) => m.userId == userId);

  FamilyMember? getMember(String userId) =>
      members.where((m) => m.userId == userId).firstOrNull;

  factory FamilyAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final membersData = data['members'] as List<dynamic>? ?? [];
    return FamilyAccount(
      id: doc.id,
      name: data['name'] as String,
      ownerId: data['ownerId'] as String,
      subscriptionId: data['subscriptionId'] as String,
      members: membersData
          .map((m) => FamilyMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      maxMembers: data['maxMembers'] as int? ?? 6,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      familyPhotoUrl: data['familyPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'subscriptionId': subscriptionId,
      'members': members.map((m) => m.toMap()).toList(),
      'maxMembers': maxMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'familyPhotoUrl': familyPhotoUrl,
    };
  }
}

/// A member of a family account
class FamilyMember {
  final String userId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final FamilyRole role;
  final DateTime joinedAt;
  final bool isActive;
  final Map<String, bool>? permissions;

  const FamilyMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    this.permissions,
  });

  bool get canViewDashboard =>
      permissions?['viewDashboard'] ?? true;

  bool get canShareRoutes =>
      permissions?['shareRoutes'] ?? true;

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: FamilyRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => FamilyRole.member,
      ),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      permissions: data['permissions'] != null
          ? Map<String, bool>.from(data['permissions'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'permissions': permissions,
    };
  }
}

/// An invitation to join a family account
class FamilyInvitation {
  final String id;
  final String familyAccountId;
  final String familyName;
  final String invitedByUserId;
  final String invitedByName;
  final String inviteeEmail;
  final String? inviteeUserId;
  final FamilyRole assignedRole;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final String? inviteCode;

  const FamilyInvitation({
    required this.id,
    required this.familyAccountId,
    required this.familyName,
    required this.invitedByUserId,
    required this.invitedByName,
    required this.inviteeEmail,
    this.inviteeUserId,
    required this.assignedRole,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.inviteCode,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  factory FamilyInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyInvitation(
      id: doc.id,
      familyAccountId: data['familyAccountId'] as String,
      familyName: data['familyName'] as String,
      invitedByUserId: data['invitedByUserId'] as String,
      invitedByName: data['invitedByName'] as String,
      inviteeEmail: data['inviteeEmail'] as String,
      inviteeUserId: data['inviteeUserId'] as String?,
      assignedRole: FamilyRole.values.firstWhere(
        (e) => e.name == data['assignedRole'],
        orElse: () => FamilyRole.member,
      ),
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      inviteCode: data['inviteCode'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyAccountId': familyAccountId,
      'familyName': familyName,
      'invitedByUserId': invitedByUserId,
      'invitedByName': invitedByName,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'assignedRole': assignedRole.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'inviteCode': inviteCode,
    };
  }
}

/// Usage statistics for a family member
class FamilyMemberUsage {
  final String userId;
  final String displayName;
  final int totalRides;
  final double totalDistanceKm;
  final int totalMinutes;
  final int routesShared;
  final int buddyMatches;
  final DateTime? lastActiveAt;

  const FamilyMemberUsage({
    required this.userId,
    required this.displayName,
    this.totalRides = 0,
    this.totalDistanceKm = 0,
    this.totalMinutes = 0,
    this.routesShared = 0,
    this.buddyMatches = 0,
    this.lastActiveAt,
  });

  factory FamilyMemberUsage.fromMap(Map<String, dynamic> data) {
    return FamilyMemberUsage(
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      totalRides: data['totalRides'] as int? ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0,
      totalMinutes: data['totalMinutes'] as int? ?? 0,
      routesShared: data['routesShared'] as int? ?? 0,
      buddyMatches: data['buddyMatches'] as int? ?? 0,
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }
}
