import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'remote_config.dart';

/// Sign-in (Firebase Auth): Google on every platform, Apple on iOS.
/// The app is fully usable signed out; an account only enables cloud backup.
class AccountService extends ChangeNotifier {
  AccountService._();
  static final instance = AccountService._();

  bool available = false;
  bool _googleReady = false;
  // Anonymous users (created silently so feedback can be submitted) are not
  // "signed in": backup and account UI only apply to real accounts.
  User? get user {
    if (!available) return null;
    final u = FirebaseAuth.instance.currentUser;
    return (u == null || u.isAnonymous) ? null : u;
  }

  bool get signedIn => user != null;
  // Hidden until the Apple Developer account and Apple devices exist; flip the
  // Remote Config parameter `apple_sign_in_enabled` to show it again.
  // iOS uses the native Apple flow; Android uses Firebase's web flow (needs the
  // Services ID return URL https://<project>.firebaseapp.com/__/auth/handler).
  bool get appleSupported =>
      (Platform.isIOS || Platform.isAndroid) &&
      RemoteSettings.appleSignInEnabled;

  String get label {
    final u = user;
    if (u == null) return '';
    return u.email ?? u.displayName ?? 'Signed in';
  }

  Future<void> start() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
      available = true;
      notifyListeners();
    } catch (_) {
      available = false;
    }
  }

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  /// Returns null on success or a user-readable problem.
  Future<String?> signInWithGoogle() async {
    if (!available) return 'Accounts are not available in this build.';
    try {
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return 'Google did not return a sign-in token.';
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return 'Google sign-in failed (${e.code.name}). Check that Google sign-in is enabled in Firebase Authentication.';
    } on FirebaseAuthException catch (e) {
      return 'Sign-in failed: ${e.code}';
    } catch (e) {
      return 'Sign-in failed: $e';
    }
  }

  Future<String?> signInWithApple() async {
    if (!available) return 'Accounts are not available in this build.';
    if (Platform.isAndroid) {
      try {
        await FirebaseAuth.instance.signInWithProvider(
          AppleAuthProvider()
            ..addScope('email')
            ..addScope('name'),
        );
        return null;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'web-context-canceled' ||
            e.code == 'canceled' ||
            e.code == 'popup-closed-by-user') {
          return null;
        }
        return 'Apple sign-in failed (${e.code}). Check the Apple provider settings in Firebase Authentication.';
      } catch (e) {
        return 'Sign-in failed: $e';
      }
    }
    try {
      final raw = _nonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(raw)).toString(),
      );
      await FirebaseAuth.instance.signInWithCredential(
        OAuthProvider('apple.com')
            .credential(idToken: apple.identityToken, rawNonce: raw),
      );
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      return 'Apple sign-in failed (${e.code.name}).';
    } on FirebaseAuthException catch (e) {
      return 'Sign-in failed: ${e.code}';
    } catch (e) {
      return 'Sign-in failed: $e';
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  /// Deletes the Firebase account. May need a recent sign-in; returns a
  /// message when it does so the caller can ask the user to sign in again.
  Future<String?> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      await signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For security, sign out and sign in again, then delete the account.';
      }
      return 'Could not delete the account: ${e.code}';
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
