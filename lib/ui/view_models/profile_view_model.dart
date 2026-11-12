import 'package:flutter/foundation.dart';
import 'package:easyqueue/data/models/user_model.dart';
import 'package:easyqueue/data/repositories/auth_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _user;
  bool _isLoading = false;

  ProfileViewModel({required this._authRepository}) {
    _user = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> updateProfile({
    required String displayName,
    String? email,
    required String phoneNumber,
    String? preferredLanguage,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    final updated = _user!.copyWith(
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      preferredLanguage: preferredLanguage,
    );

    await _authRepository.updateProfile(updated);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateNotificationPreferences(NotificationPreferences prefs) async {
    if (_user == null) return;
    await _authRepository.updateNotificationPreferences(prefs);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }
}
