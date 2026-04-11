/// Auth Riverpod providers
/// Exposes: authRepositoryProvider, authStateProvider, currentUserProvider,
///           isEmailVerifiedProvider, splashVideoCompleteProvider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ─── Splash Video Gate ────────────────────────────────────────────────────────

/// True once the splash video has finished playing.
/// The router redirect waits for this before navigating away from splash.
final splashVideoCompleteProvider = StateProvider<bool>((ref) => false);

// ─── Auth State Stream ────────────────────────────────────────────────────────

/// Streams AppUser? — null means signed out.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─── Current User (nullable) ──────────────────────────────────────────────────

/// Convenience — returns the current AppUser or null, no loading state.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ─── Is Authenticated ─────────────────────────────────────────────────────────

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ─── Email Verified ───────────────────────────────────────────────────────────

final isEmailVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.emailVerified ?? false;
});

// ─── Auth Actions Notifier ────────────────────────────────────────────────────

/// Handles sign-in / sign-up / sign-out actions.
/// State is the async operation result — null = idle, error = failed.

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInWithGoogle);
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInWithApple);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.updateProfile(
        uid: uid,
        displayName: displayName,
        phone: phone,
      ),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.sendPasswordResetEmail(email));
  }

  Future<void> resendVerificationEmail() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.sendEmailVerification);
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    final error = await _repo.deleteAccount();
    if (error != null) {
      state = AsyncError(Exception(error), StackTrace.current);
      throw Exception(error);
    } else {
      state = const AsyncData(null);
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
