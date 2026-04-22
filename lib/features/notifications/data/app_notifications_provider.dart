/// CYKEL — App Notifications Provider

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/notifications_list_screen.dart';

final appNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map(AppNotification.fromFirestore).toList());
});
