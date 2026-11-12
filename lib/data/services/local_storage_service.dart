import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setUserId(String userId) async {
    await init();
    await _prefs?.setString(AppConstants.keyUserId, userId);
  }

  String? getUserId() {
    return _prefs?.getString(AppConstants.keyUserId);
  }

  Future<void> setIsGuest(bool isGuest) async {
    await init();
    await _prefs?.setBool(AppConstants.keyIsGuest, isGuest);
  }

  bool isGuest() {
    return _prefs?.getBool(AppConstants.keyIsGuest) ?? false;
  }

  Future<void> setGuestToken(String token) async {
    await init();
    await _prefs?.setString(AppConstants.keyGuestToken, token);
  }

  String? getGuestToken() {
    return _prefs?.getString(AppConstants.keyGuestToken);
  }

  Future<void> setOnboarded(bool onboarded) async {
    await init();
    await _prefs?.setBool(AppConstants.keyOnboarded, onboarded);
  }

  bool isOnboarded() {
    return _prefs?.getBool(AppConstants.keyOnboarded) ?? false;
  }

  Future<void> setUserProfile({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    await init();
    if (name != null) await _prefs?.setString('user_name', name);
    if (email != null) await _prefs?.setString('user_email', email);
    if (phone != null) await _prefs?.setString('user_phone', phone);
    if (photoUrl != null) await _prefs?.setString('user_photo', photoUrl);
  }

  String? getUserName() => _prefs?.getString('user_name');
  String? getUserEmail() => _prefs?.getString('user_email');
  String? getUserPhone() => _prefs?.getString('user_phone');
  String? getUserPhoto() => _prefs?.getString('user_photo');

  Future<void> clearSession() async {
    await init();
    await _prefs?.remove(AppConstants.keyUserId);
    await _prefs?.remove(AppConstants.keyIsGuest);
    await _prefs?.remove(AppConstants.keyGuestToken);
    await _prefs?.remove('user_name');
    await _prefs?.remove('user_email');
    await _prefs?.remove('user_phone');
    await _prefs?.remove('user_photo');
  }
}
