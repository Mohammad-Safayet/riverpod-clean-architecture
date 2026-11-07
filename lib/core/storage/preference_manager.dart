import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key/value storage. Tokens go in `TokenStorage` (secure storage) instead.
///
/// Add a typed getter/setter per key rather than passing raw strings around.
class PreferenceManager {
  PreferenceManager(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLanguageCode = 'language_code';
  static const _keySessionUser = 'session_user';

  String? get languageCode => _prefs.getString(_keyLanguageCode);
  Future<void> setLanguageCode(String code) => _prefs.setString(_keyLanguageCode, code);

  String? get sessionUserJson => _prefs.getString(_keySessionUser);
  Future<void> setSessionUserJson(String? json) =>
      json == null ? _prefs.remove(_keySessionUser) : _prefs.setString(_keySessionUser, json);
}
