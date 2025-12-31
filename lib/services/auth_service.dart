import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userTypeKey = 'user_type';
  static const String _userEmailKey = 'user_email';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user session data
  Future<bool> saveUserSession(String email, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userTypeKey, userType);
    return await prefs.setBool(_isLoggedInKey, true);
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get logged in user type
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // Get logged in user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Log out user
  Future<bool> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userTypeKey);
    return await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> isFirstTimeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('has_logged_in_before');
  }

  Future<void> markFirstTimeLoginComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in_before', true);
  }
}
