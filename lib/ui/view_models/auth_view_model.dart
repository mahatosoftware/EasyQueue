import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:easyqueue/data/models/user_model.dart';
import 'package:easyqueue/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  AuthViewModel({required this._authRepository}) {
    _currentUser = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get verificationId => _verificationId;

  Future<void> initSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.initializeSession();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UC-003: Sign In with Email & Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UC-002: Sign Up / Create Account with Email & Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UC-003: Send Password Reset Email
  Future<bool> sendPasswordReset({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordReset(email: email);
      return true;
    } catch (e) {
      _errorMessage = _parseAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// UC-003: Sign In with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseAuthError(dynamic error) {
    final str = error.toString();
    if (str.contains('user-not-found')) {
      return 'No account found with this email. Please check or sign up.';
    } else if (str.contains('wrong-password') || str.contains('invalid-credential')) {
      return 'Incorrect password or credentials. Please try again.';
    } else if (str.contains('email-already-in-use')) {
      return 'An account already exists for this email address.';
    } else if (str.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (str.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    } else if (str.contains('network-request-failed')) {
      return 'Network connection issue. Please check your internet.';
    }
    return str.replaceAll('Exception:', '').trim();
  }

  /// Send SMS OTP via Firebase Authentication
  Future<bool> sendPhoneOtp(String fullPhoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<bool>();
    await _authRepository.sendPhoneOtp(
      fullPhoneNumber: fullPhoneNumber,
      onCodeSent: (vId) {
        _verificationId = vId;
        _isLoading = false;
        notifyListeners();
        completer.complete(true);
      },
      onError: (err) {
        _errorMessage = err;
        _isLoading = false;
        notifyListeners();
        completer.complete(false);
      },
    );
    return completer.future;
  }

  Future<bool> loginWithPhoneOtp({
    required String phoneNumber,
    required String countryCode,
    required String otp,
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithPhoneOtp(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        otp: otp,
        verificationId: _verificationId,
        name: name,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Invalid verification code or network failure: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginAsGuest({String? name, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInAsGuest(name: name, phone: phone);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimGuestTicket({
    required String phoneNumber,
    required String otp,
    required String targetName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.claimGuestTicket(
        phoneNumber: phoneNumber,
        otp: otp,
        targetName: targetName,
        verificationId: _verificationId,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to claim ticket: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authRepository.signOut();
    _isLoading = false;
    notifyListeners();
  }
}
