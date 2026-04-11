/// Auth Repository — wraps Firebase Auth + Firestore user profile.
/// Handles: email/password, Google Sign-In, Apple Sign-In, sign-out.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/app_user.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  // ─── Stream ────────────────────────────────────────────────────────────────

  /// Emits [AppUser] when signed in, null when signed out.
  ///
  /// Zero Firestore calls — maps Firebase Auth state directly so the stream
  /// always emits immediately on startup. The full Firestore profile is
  /// fetched lazily by the UI after navigation via [fetchProfile].
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map((user) {
        if (user == null) return null;
        return _userFromFirebase(user);
      });

  /// Fetch (or create) the full Firestore profile for the signed-in user.
  /// Call this from the home/profile screen after navigation — not at startup.
  Future<AppUser> fetchProfile(User firebaseUser) =>
      _fetchOrCreateProfile(firebaseUser);

  /// Minimal [AppUser] built from Firebase Auth data alone — no Firestore.
  AppUser _userFromFirebase(User user) => AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        role: AppConstants.roleRider,
        emailVerified: user.emailVerified,
        photoUrl: user.photoURL,
      );

  /// Current user synchronously (null if not signed in).
  User? get currentFirebaseUser => _auth.currentUser;

  // ─── Email / Password ──────────────────────────────────────────────────────

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _fetchOrCreateProfile(cred.user!);
  }

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    await cred.user!.sendEmailVerification();
    return _fetchOrCreateProfile(cred.user!);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Require email verification before allowing certain actions
  void requireEmailVerification() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    if (!user.emailVerified) {
      throw const EmailNotVerifiedException();
    }
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────

  // Web client ID from google-services.json (client_type: 3).
  // Required for Firebase Auth to get an idToken from Google Sign-In.
  static const _webClientId =
      '875600194960-hq3vhlr27r3kn33g7rkgi9b01ke92tu8.apps.googleusercontent.com';

  Future<AppUser> signInWithGoogle() async {
    final googleUser =
        await GoogleSignIn(serverClientId: _webClientId).signIn();
    if (googleUser == null) throw const AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    debugPrint('Google idToken: ${idToken != null ? "present" : "NULL"}');
    debugPrint('Google accessToken: ${accessToken != null ? "present" : "NULL"}');
    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _fetchOrCreateProfile(cred.user!);
  }

  // ─── Apple Sign-In ─────────────────────────────────────────────────────────

  Future<AppUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(credential);

      // Apple only gives name on first sign-in
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().join(' ').trim();

      if (fullName.isNotEmpty && cred.user!.displayName == null) {
        await cred.user!.updateDisplayName(fullName);
      }

      return _fetchOrCreateProfile(cred.user!);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle user cancellation gracefully
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      // Re-throw other Apple authorization errors
      rethrow;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ─── Delete Account (GDPR) ────────────────────────────────────────────────

  /// Deletes the user's account and all associated data (GDPR-compliant).
  /// This calls a Cloud Function to cascade delete all user data:
  /// - Rides, marketplace listings, chats, providers, reports, user doc, auth
  /// Returns an error message if deletion fails or re-authentication is required.
  Future<String?> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return 'No user signed in';
    
    try {
      // Call Cloud Function to cascade delete all user data
      final callable = _functions.httpsCallable('deleteUserAccount');
      await callable.call<Map<String, dynamic>>();
      
      // Success - user is automatically signed out when auth account is deleted
      return null;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return 'Please sign in again before deleting your account';
      }
      return 'Failed to delete account: ${e.message ?? e.code}';
    } catch (e) {
      return 'Failed to delete account: $e';
    }
  }

  // ─── Update Profile ────────────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    final update = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      update['displayName'] = displayName.trim();
      update['displayNameLower'] = displayName.trim().toLowerCase();
    }
    if (phone != null) update['phone'] = phone.trim();
    if (update.isEmpty) return;
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update(update);
    if (displayName != null &&
        displayName.trim().isNotEmpty &&
        _auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(displayName.trim());
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<AppUser> _fetchOrCreateProfile(User firebaseUser) async {
    final doc = await _firestore
        .collection(AppConstants.colUsers)
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(firebaseUser.uid, doc.data()!);
    }

    // Profile doesn't exist yet — create it (onUserCreate Cloud Function
    // also does this, but we need it immediately on sign-up)
    final newUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      role: AppConstants.roleRider,
      emailVerified: firebaseUser.emailVerified,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.colUsers)
        .doc(firebaseUser.uid)
        .set({
      ...newUser.toMap(),
      'displayNameLower': (firebaseUser.displayName ?? '').toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newUser;
  }
}

// ─── Custom Exceptions ────────────────────────────────────────────────────────

class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'Sign-in was cancelled.';
}

class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();

  @override
  String toString() => 'Email not verified. Please check your inbox and verify your email.';
}

/// Maps Firebase Auth error codes to user-friendly localised messages.
String authErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.errInvalidCredential;
      case 'email-already-in-use':
        return l10n.errEmailInUse;
      case 'weak-password':
        return l10n.errWeakPassword;
      case 'invalid-email':
        return l10n.errInvalidEmail;
      case 'network-request-failed':
        return l10n.errNoInternet;
      case 'too-many-requests':
        return l10n.errTooManyRequests;
      case 'user-disabled':
        return l10n.errUserDisabled;
      case 'requires-recent-login':
        return l10n.errRequiresRecentLogin;
      default:
        return l10n.errGeneric;
    }
  }
  if (error is AuthCancelledException) return l10n.errCancelled;
  if (error is PlatformException) {
    // Log the real error so it shows in Flutter console
    debugPrint('Google Sign-In PlatformException: ${error.code} — ${error.message}');
    if (error.code == 'network_error') return l10n.errNoInternet;
    if (error.code == 'sign_in_cancelled') return l10n.errCancelled;
    if (error.code == 'sign_in_failed') {
      return 'Google Sign-In failed: ${error.message ?? error.code}';
    }
    return 'Sign-in error: ${error.message ?? error.code}';
  }
  debugPrint('Auth error (unknown type ${error.runtimeType}): $error');
  return l10n.errGeneric;
}
