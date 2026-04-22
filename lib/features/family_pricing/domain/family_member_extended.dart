import 'package:cloud_firestore/cloud_firestore.dart';

/// Member type based on account access
enum MemberType {
  /// Has CYKEL account, accepted invitation
  linked,
  /// No app account (young children), managed by parent
  managed,
  /// Invite sent but not yet accepted
  pending,
  /// Temporary access with expiry
  guest;

  String get displayName {
    switch (this) {
      case MemberType.linked:
        return 'Linked';
      case MemberType.managed:
        return 'Managed';
      case MemberType.pending:
        return 'Pending';
      case MemberType.guest:
        return 'Guest';
    }
  }
}

/// Relationship to the family admin/owner
enum FamilyRelationship {
  spouse,
  child,
  parent,
  sibling,
  grandparent,
  other;

  String get displayName {
    switch (this) {
      case FamilyRelationship.spouse:
        return 'Spouse/Partner';
      case FamilyRelationship.child:
        return 'Child';
      case FamilyRelationship.parent:
        return 'Parent';
      case FamilyRelationship.sibling:
        return 'Sibling';
      case FamilyRelationship.grandparent:
        return 'Grandparent';
      case FamilyRelationship.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case FamilyRelationship.spouse:
        return '💑';
      case FamilyRelationship.child:
        return '👶';
      case FamilyRelationship.parent:
        return '👨‍👩‍👦';
      case FamilyRelationship.sibling:
        return '👫';
      case FamilyRelationship.grandparent:
        return '👴';
      case FamilyRelationship.other:
        return '👤';
    }
  }
}

/// Member permissions for location and visibility
class MemberPermissions {
  /// Can share location with family (enforced ON for children)
  final bool locationSharing;

  /// Visible to other adult members (optional for adults)
  final bool visibleToAdults;

  /// Can see other family members' locations
  final bool canSeeFamily;

  /// Has admin dashboard access
  final bool canAccessDashboard;

  /// Can start rides independently
  final bool canStartRides;

  /// Receives ride notifications
  final bool receiveRideNotifications;

  const MemberPermissions({
    this.locationSharing = true,
    this.visibleToAdults = true,
    this.canSeeFamily = true,
    this.canAccessDashboard = false,
    this.canStartRides = true,
    this.receiveRideNotifications = true,
  });

  /// Default permissions for admin
  factory MemberPermissions.admin() => const MemberPermissions(
        locationSharing: true,
        visibleToAdults: true,
        canSeeFamily: true,
        canAccessDashboard: true,
        canStartRides: true,
        receiveRideNotifications: true,
      );

  /// Default permissions for adult member
  factory MemberPermissions.adult() => const MemberPermissions(
        locationSharing: true, // Optional - can toggle off
        visibleToAdults: true, // Optional - can toggle off
        canSeeFamily: true,
        canAccessDashboard: false,
        canStartRides: true,
        receiveRideNotifications: true,
      );

  /// Default permissions for teen (10-17)
  factory MemberPermissions.teen() => const MemberPermissions(
        locationSharing: true, // Enforced ON
        visibleToAdults: true,
        canSeeFamily: true,
        canAccessDashboard: false,
        canStartRides: true,
        receiveRideNotifications: true,
      );

  /// Default permissions for child (under 10)
  factory MemberPermissions.child() => const MemberPermissions(
        locationSharing: true, // Enforced ON
        visibleToAdults: true,
        canSeeFamily: false, // Can't see others by default
        canAccessDashboard: false,
        canStartRides: false, // Managed by parent
        receiveRideNotifications: false,
      );

  /// Default permissions for guest
  factory MemberPermissions.guest() => const MemberPermissions(
        locationSharing: true, // Optional
        visibleToAdults: true,
        canSeeFamily: true,
        canAccessDashboard: false,
        canStartRides: true,
        receiveRideNotifications: false,
      );

  factory MemberPermissions.fromMap(Map<String, dynamic> data) {
    return MemberPermissions(
      locationSharing: data['locationSharing'] as bool? ?? true,
      visibleToAdults: data['visibleToAdults'] as bool? ?? true,
      canSeeFamily: data['canSeeFamily'] as bool? ?? true,
      canAccessDashboard: data['canAccessDashboard'] as bool? ?? false,
      canStartRides: data['canStartRides'] as bool? ?? true,
      receiveRideNotifications: data['receiveRideNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationSharing': locationSharing,
      'visibleToAdults': visibleToAdults,
      'canSeeFamily': canSeeFamily,
      'canAccessDashboard': canAccessDashboard,
      'canStartRides': canStartRides,
      'receiveRideNotifications': receiveRideNotifications,
    };
  }

  MemberPermissions copyWith({
    bool? locationSharing,
    bool? visibleToAdults,
    bool? canSeeFamily,
    bool? canAccessDashboard,
    bool? canStartRides,
    bool? receiveRideNotifications,
  }) {
    return MemberPermissions(
      locationSharing: locationSharing ?? this.locationSharing,
      visibleToAdults: visibleToAdults ?? this.visibleToAdults,
      canSeeFamily: canSeeFamily ?? this.canSeeFamily,
      canAccessDashboard: canAccessDashboard ?? this.canAccessDashboard,
      canStartRides: canStartRides ?? this.canStartRides,
      receiveRideNotifications: receiveRideNotifications ?? this.receiveRideNotifications,
    );
  }
}

/// Child safety settings (for members under 18)
class ChildSafetySettings {
  /// Send location to parents during all rides
  final bool sendLocationToParents;

  /// Maximum allowed ride distance in km (0 = unlimited)
  final double maxRideDistanceKm;

  /// Curfew time - alert if riding after this time (null = no curfew)
  final DateTime? curfewTime;

  /// Alert parents when child starts a ride
  final bool alertOnRideStart;

  /// Alert parents when child ends a ride
  final bool alertOnRideEnd;

  const ChildSafetySettings({
    this.sendLocationToParents = true,
    this.maxRideDistanceKm = 10.0,
    this.curfewTime,
    this.alertOnRideStart = true,
    this.alertOnRideEnd = true,
  });

  factory ChildSafetySettings.fromMap(Map<String, dynamic> data) {
    return ChildSafetySettings(
      sendLocationToParents: data['sendLocationToParents'] as bool? ?? true,
      maxRideDistanceKm: (data['maxRideDistanceKm'] as num?)?.toDouble() ?? 10.0,
      curfewTime: data['curfewTime'] != null
          ? (data['curfewTime'] as Timestamp).toDate()
          : null,
      alertOnRideStart: data['alertOnRideStart'] as bool? ?? true,
      alertOnRideEnd: data['alertOnRideEnd'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sendLocationToParents': sendLocationToParents,
      'maxRideDistanceKm': maxRideDistanceKm,
      'curfewTime': curfewTime != null ? Timestamp.fromDate(curfewTime!) : null,
      'alertOnRideStart': alertOnRideStart,
      'alertOnRideEnd': alertOnRideEnd,
    };
  }

  ChildSafetySettings copyWith({
    bool? sendLocationToParents,
    double? maxRideDistanceKm,
    DateTime? curfewTime,
    bool? alertOnRideStart,
    bool? alertOnRideEnd,
  }) {
    return ChildSafetySettings(
      sendLocationToParents: sendLocationToParents ?? this.sendLocationToParents,
      maxRideDistanceKm: maxRideDistanceKm ?? this.maxRideDistanceKm,
      curfewTime: curfewTime ?? this.curfewTime,
      alertOnRideStart: alertOnRideStart ?? this.alertOnRideStart,
      alertOnRideEnd: alertOnRideEnd ?? this.alertOnRideEnd,
    );
  }
}

/// Extended family member with all new fields
class ExtendedFamilyMember {
  final String id;
  final String? userId; // Null for managed children
  final String firstName;
  final String? lastName;
  final DateTime dateOfBirth;
  final FamilyRelationship relationship;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final MemberType memberType;
  final MemberPermissions permissions;
  final ChildSafetySettings? childSafetySettings;
  final DateTime? guestExpiryDate; // For guest members
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isActive;

  const ExtendedFamilyMember({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    required this.dateOfBirth,
    required this.relationship,
    this.email,
    this.phone,
    this.photoUrl,
    required this.memberType,
    required this.permissions,
    this.childSafetySettings,
    this.guestExpiryDate,
    required this.createdAt,
    this.lastActiveAt,
    this.isActive = true,
  });

  String get displayName => lastName != null ? '$firstName $lastName' : firstName;

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get isChild => age < 18;
  bool get isManagedChild => age < 10;
  bool get isTeen => age >= 10 && age < 18;
  bool get isAdult => age >= 18;
  bool get hasAppLogin => age >= 10 && memberType != MemberType.managed;
  bool get isGuest => memberType == MemberType.guest;
  bool get isPending => memberType == MemberType.pending;
  bool get isLinked => memberType == MemberType.linked;
  bool get isManaged => memberType == MemberType.managed;

  /// Whether this member can disable their own location tracking
  bool get canDisableTracking => isAdult;

  factory ExtendedFamilyMember.fromMap(Map<String, dynamic> data) {
    return ExtendedFamilyMember(
      id: data['id'] as String,
      userId: data['userId'] as String?,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String?,
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      relationship: FamilyRelationship.values.firstWhere(
        (e) => e.name == data['relationship'],
        orElse: () => FamilyRelationship.other,
      ),
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      memberType: MemberType.values.firstWhere(
        (e) => e.name == data['memberType'],
        orElse: () => MemberType.pending,
      ),
      permissions: data['permissions'] != null
          ? MemberPermissions.fromMap(data['permissions'] as Map<String, dynamic>)
          : const MemberPermissions(),
      childSafetySettings: data['childSafetySettings'] != null
          ? ChildSafetySettings.fromMap(
              data['childSafetySettings'] as Map<String, dynamic>)
          : null,
      guestExpiryDate: data['guestExpiryDate'] != null
          ? (data['guestExpiryDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'relationship': relationship.name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'memberType': memberType.name,
      'permissions': permissions.toMap(),
      'childSafetySettings': childSafetySettings?.toMap(),
      'guestExpiryDate':
          guestExpiryDate != null ? Timestamp.fromDate(guestExpiryDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'isActive': isActive,
    };
  }

  ExtendedFamilyMember copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    FamilyRelationship? relationship,
    String? email,
    String? phone,
    String? photoUrl,
    MemberType? memberType,
    MemberPermissions? permissions,
    ChildSafetySettings? childSafetySettings,
    DateTime? guestExpiryDate,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return ExtendedFamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      memberType: memberType ?? this.memberType,
      permissions: permissions ?? this.permissions,
      childSafetySettings: childSafetySettings ?? this.childSafetySettings,
      guestExpiryDate: guestExpiryDate ?? this.guestExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Emergency contact for the family
class EmergencyContact {
  final String name;
  final String phone;
  final String? email;
  final String? relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> data) {
    return EmergencyContact(
      name: data['name'] as String,
      phone: data['phone'] as String,
      email: data['email'] as String?,
      relationship: data['relationship'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
    };
  }
}

/// Home address for geofencing
class FamilyAddress {
  final String address;
  final double latitude;
  final double longitude;
  final String? label; // "Home", "School", etc.

  const FamilyAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  factory FamilyAddress.fromMap(Map<String, dynamic> data) {
    return FamilyAddress(
      address: data['address'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      label: data['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
    };
  }
}
