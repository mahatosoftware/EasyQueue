import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  final LocalStorageService _storageService;
  final FirebaseAuthService? _firebaseAuthService;
  final FirebaseFirestore? _firestore;

  UserModel? _currentUser;
  final _userController = StreamController<UserModel?>.broadcast();
  StreamSubscription? _fbAuthSub;

  AuthRepository({
    required this._storageService,
    this._firebaseAuthService,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? _resolveFirestore() {
    _listenToFirebaseAuthChanges();
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<UserModel?> get authStateChanges => _userController.stream;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  void _listenToFirebaseAuthChanges() {
    _fbAuthSub = _firebaseAuthService?.authStateChanges.listen((fbUser) async {
      if (fbUser != null) {
        final profile = await _fetchOrCreateFirestoreUser(fbUser);
        _currentUser = profile;
        _userController.add(_currentUser);
      } else {
        _currentUser = null;
        _userController.add(null);
      }
    });
  }

  Future<UserModel?> initializeSession() async {
    await _storageService.init();

    // 1. Check if Firebase already has an active authenticated user
    final fbUser = _firebaseAuthService?.currentFirebaseUser;
    if (fbUser != null) {
      _currentUser = await _fetchOrCreateFirestoreUser(fbUser);
      _userController.add(_currentUser);
      return _currentUser;
    }

    // 2. Check local session storage
    final savedUserId = _storageService.getUserId();
    final isGuestUser = _storageService.isGuest();

    if (savedUserId != null) {
      _currentUser = UserModel(
        id: savedUserId,
        displayName: _storageService.getUserName() ?? (isGuestUser ? 'Guest Customer' : 'Customer'),
        email: _storageService.getUserEmail(),
        phoneNumber: _storageService.getUserPhone() ?? '',
        countryCode: '+1',
        photoUrl: _storageService.getUserPhoto(),
        preferredLanguage: 'en',
        isGuest: isGuestUser,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      _currentUser = null;
    }

    _userController.add(_currentUser);
    return _currentUser;
  }

  Future<UserModel> _fetchOrCreateFirestoreUser(User fbUser) async {
    if (_firestore != null) {
      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          return UserModel.fromMap(data, fbUser.uid);
        }
      } catch (e) {
        debugPrint('Firestore fetch user notice: $e');
      }
    }

    final String displayName = fbUser.displayName?.trim().isNotEmpty == true
        ? fbUser.displayName!.trim()
        : (fbUser.isAnonymous ? 'Guest Customer' : (fbUser.email?.split('@').first ?? 'Customer'));

    final user = UserModel(
      id: fbUser.uid,
      displayName: displayName,
      email: fbUser.email,
      phoneNumber: fbUser.phoneNumber ?? '',
      countryCode: '+1',
      photoUrl: fbUser.photoURL,
      preferredLanguage: 'en',
      isGuest: fbUser.isAnonymous,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _syncUserToFirestore(user);
    return user;
  }

  Future<void> _syncUserToFirestore(UserModel user) async {
    await _storageService.setUserId(user.id);
    await _storageService.setIsGuest(user.isGuest);
    await _storageService.setUserProfile(
      name: user.displayName,
      email: user.email,
      phone: user.phoneNumber,
      photoUrl: user.photoUrl,
    );

    if (_firestore != null) {
      try {
        final userDocRef = _firestore.collection('users').doc(user.id);
        final docSnap = await userDocRef.get();
        final isNew = !docSnap.exists;

        await userDocRef.set({
          'id': user.id,
          'name': user.displayName.isNotEmpty ? user.displayName : 'Customer',
          if (user.email != null && user.email!.isNotEmpty) 'email': user.email,
          if (user.phoneNumber.isNotEmpty) 'phoneNumber': user.phoneNumber,
          'role': 'CUSTOMER',
          if (user.photoUrl != null && user.photoUrl!.isNotEmpty) 'avatarUrl': user.photoUrl,
          if (isNew) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sync user notice: $e');
      }
    }
  }

  /// UC-003: Sign In with Email & Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    String userId = 'usr_${const Uuid().v4().substring(0, 8)}';
    String displayName = email.split('@').first;
    String? photoUrl;

    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      final cred = await _firebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred?.user != null) {
        final fbUser = cred!.user!;
        return await _fetchOrCreateFirestoreUser(fbUser);
      }
    }

    final user = UserModel(
      id: userId,
      displayName: displayName.isNotEmpty ? displayName : 'Customer',
      email: email,
      phoneNumber: '',
      countryCode: '+1',
      photoUrl: photoUrl,
      preferredLanguage: 'en',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    await _syncUserToFirestore(user);
    _userController.add(_currentUser);
    return user;
  }

  /// UC-002: Create Account / Sign Up with Email & Password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    String userId = 'usr_${const Uuid().v4().substring(0, 8)}';
    String? photoUrl;

    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      final cred = await _firebaseAuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (cred?.user != null) {
        final fbUser = cred!.user!;
        final user = UserModel(
          id: fbUser.uid,
          displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Customer',
          email: email,
          phoneNumber: '',
          countryCode: '+1',
          photoUrl: fbUser.photoURL,
          preferredLanguage: 'en',
          isGuest: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _currentUser = user;
        await _syncUserToFirestore(user);
        _userController.add(_currentUser);
        return user;
      }
    }

    final user = UserModel(
      id: userId,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Customer',
      email: email,
      phoneNumber: '',
      countryCode: '+1',
      photoUrl: photoUrl,
      preferredLanguage: 'en',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    await _syncUserToFirestore(user);
    _userController.add(_currentUser);
    return user;
  }

  /// UC-003: Send Password Reset Email
  Future<void> sendPasswordReset({required String email}) async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      await _firebaseAuthService.sendPasswordResetEmail(email: email);
    }
  }

  /// UC-003: Sign In with Google
  Future<UserModel?> signInWithGoogle() async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      final cred = await _firebaseAuthService.signInWithGoogle();
      if (cred == null || cred.user == null) {
        return null;
      }
      return await _fetchOrCreateFirestoreUser(cred.user!);
    }

    final user = UserModel(
      id: 'usr_google_${const Uuid().v4().substring(0, 8)}',
      displayName: 'Google Customer',
      email: 'customer@gmail.com',
      phoneNumber: '',
      countryCode: '+1',
      preferredLanguage: 'en',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    await _syncUserToFirestore(user);
    _userController.add(_currentUser);
    return user;
  }

  /// Request SMS OTP using Firebase Phone Auth
  Future<void> sendPhoneOtp({
    required String fullPhoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      await _firebaseAuthService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        onCodeSent: (verificationId, _) => onCodeSent(verificationId),
        onVerificationFailed: (e) => onError(e.message ?? 'Verification failed'),
        onVerificationCompleted: (credential) async {},
        onCodeAutoRetrievalTimeout: (_) {},
      );
    } else {
      onError('Firebase Phone Authentication is unavailable.');
    }
  }

  Future<UserModel> signInWithPhoneOtp({
    required String phoneNumber,
    required String countryCode,
    required String otp,
    String? verificationId,
    String? name,
  }) async {
    if (_firebaseAuthService != null &&
        _firebaseAuthService.isFirebaseAvailable &&
        verificationId != null &&
        verificationId.isNotEmpty) {
      final cred = await _firebaseAuthService.signInWithOtp(
        verificationId: verificationId,
        smsCode: otp,
      );
      if (cred?.user != null) {
        final fbUser = cred!.user!;
        if (name != null && name.isNotEmpty) {
          await _firebaseAuthService.updateProfile(displayName: name);
        }
        return await _fetchOrCreateFirestoreUser(fbUser);
      }
    }

    throw Exception('Failed to sign in with phone OTP. Please check the verification code.');
  }

  Future<UserModel> signInAsGuest({String? name, String? phone}) async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      final cred = await _firebaseAuthService.signInAnonymously();
      if (cred?.user != null) {
        final guestId = cred!.user!.uid;
        final guestUser = UserModel(
          id: guestId,
          displayName: (name != null && name.isNotEmpty) ? name : 'Guest Customer',
          phoneNumber: phone ?? '',
          countryCode: '+1',
          isGuest: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _currentUser = guestUser;
        await _syncUserToFirestore(guestUser);
        _userController.add(_currentUser);
        return guestUser;
      }
    }

    final localGuestId = 'guest_${const Uuid().v4().substring(0, 8)}';
    final user = UserModel(
      id: localGuestId,
      displayName: (name != null && name.isNotEmpty) ? name : 'Guest Customer',
      phoneNumber: phone ?? '',
      countryCode: '+1',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentUser = user;
    await _syncUserToFirestore(user);
    _userController.add(_currentUser);
    return user;
  }

  /// UC-004: Universal Ticket Claiming - links guest credentials to full account
  Future<UserModel> claimGuestTicket({
    required String phoneNumber,
    required String otp,
    required String targetName,
    String? verificationId,
  }) async {
    if (_firebaseAuthService != null &&
        _firebaseAuthService.isFirebaseAvailable &&
        verificationId != null &&
        verificationId.isNotEmpty) {
      final cred = await _firebaseAuthService.linkGuestWithPhone(
        verificationId: verificationId,
        smsCode: otp,
      );
      if (cred?.user != null) {
        final finalUserId = cred!.user!.uid;
        await _firebaseAuthService.updateProfile(displayName: targetName);
        final fullUser = (_currentUser ?? UserModel(
          id: finalUserId,
          displayName: targetName,
          phoneNumber: phoneNumber,
          countryCode: '+1',
          isGuest: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).copyWith(
          displayName: targetName,
          phoneNumber: phoneNumber,
          isGuest: false,
        );

        _currentUser = fullUser;
        await _syncUserToFirestore(fullUser);
        _userController.add(_currentUser);
        return fullUser;
      }
    }

    throw Exception('Failed to claim ticket. Could not verify phone credentials.');
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _currentUser = updatedUser;
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      await _firebaseAuthService.updateProfile(displayName: updatedUser.displayName);
    }
    await _syncUserToFirestore(updatedUser);
    _userController.add(_currentUser);
  }

  Future<void> updateNotificationPreferences(NotificationPreferences prefs) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(notificationPreferences: prefs);
    await _syncUserToFirestore(_currentUser!);
    _userController.add(_currentUser);
  }

  Future<void> signOut() async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      await _firebaseAuthService.signOut();
    }
    await _storageService.clearSession();
    _currentUser = null;
    _userController.add(null);
  }

  Future<void> deleteAccount() async {
    if (_firebaseAuthService != null && _firebaseAuthService.isFirebaseAvailable) {
      await _firebaseAuthService.deleteAccount();
    }
    if (_firestore != null && _currentUser != null) {
      try {
        await _firestore.collection('users').doc(_currentUser!.id).delete();
      } catch (_) {}
    }
    await _storageService.clearSession();
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _fbAuthSub?.cancel();
    _userController.close();
  }
}
