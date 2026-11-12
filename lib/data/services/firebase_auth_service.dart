import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuth? _auth;

  FirebaseAuthService({FirebaseAuth? auth}) {
    try {
      _auth = auth ?? FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth instance note: $e');
    }
  }

  bool get isFirebaseAvailable => _auth != null;
  User? get currentFirebaseUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// UC-003: Email and Password Sign In
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!isFirebaseAvailable) return null;
    return await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// UC-002: Customer Registration with Email and Password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!isFirebaseAvailable) return null;
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return cred;
  }

  /// UC-003: Password Reset via Email
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!isFirebaseAvailable) return;
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  /// UC-003: Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseAvailable) return null;
    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await _auth!.signInWithPopup(googleProvider);
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '274807226246-pb369uv22g8r9siv509ed0dvfdqcar7l.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth!.signInWithCredential(credential);
    }
  }

  /// UC-004: Guest anonymous authentication
  Future<UserCredential?> signInAnonymously() async {
    if (!isFirebaseAvailable) return null;
    try {
      return await _auth!.signInAnonymously();
    } catch (e) {
      debugPrint('Firebase signInAnonymously error: $e');
      return null;
    }
  }

  /// UC-002, UC-003: Phone Number OTP verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (!isFirebaseAvailable) return;
    await _auth!.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Sign in using received SMS code and verificationId
  Future<UserCredential?> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!isFirebaseAvailable) return null;
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth!.signInWithCredential(credential);
  }

  /// UC-004: Claim & Link guest account with verified phone credential
  Future<UserCredential?> linkGuestWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!isFirebaseAvailable || _auth!.currentUser == null) return null;
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      return await _auth!.currentUser!.linkWithCredential(credential);
    } catch (e) {
      debugPrint('Link with credential note: $e');
      // If linking fails (e.g. credential already in use), sign in with credential directly
      return await _auth!.signInWithCredential(credential);
    }
  }

  /// Update display name on Firebase User
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (!isFirebaseAvailable || _auth!.currentUser == null) return;
    await _auth!.currentUser!.updateDisplayName(displayName);
    if (photoUrl != null) {
      await _auth!.currentUser!.updatePhotoURL(photoUrl);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!isFirebaseAvailable) return;
    try {
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
    } catch (_) {}
    await _auth!.signOut();
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    if (!isFirebaseAvailable || _auth!.currentUser == null) return;
    await _auth!.currentUser!.delete();
  }
}
