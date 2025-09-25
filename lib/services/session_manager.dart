import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

/// SessionManager provides static access to session data throughout the application
/// This allows accessing user information without requiring context or provider instance
class SessionManager {
  static UserModel? _cachedUser;
  static bool _isInitialized = false;

  /// Initialize the session manager by loading data from SharedPreferences
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final String? userData = prefs.getString('user_data');
        if (userData != null) {
          final Map<String, dynamic> userJson = json.decode(userData);
          _cachedUser = UserModel.fromJson(userJson);
        }
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing SessionManager: $e');
      _isInitialized = true;
    }
  }

  /// Update cached user data (called from AuthService when login/logout occurs)
  static void updateUser(UserModel? user) {
    _cachedUser = user;
  }

  /// Clear all cached data (called during logout)
  static void clear() {
    _cachedUser = null;
  }

  // User Information Getters
  static int? get userId => _cachedUser?.userId;
  static String get fullName => _cachedUser?.fullName ?? '';
  static String get email => _cachedUser?.email ?? '';
  static String get designation => _cachedUser?.designation ?? '';
  static String get roleName => _cachedUser?.roleName ?? '';
  static String get departmentName => _cachedUser?.departmentName ?? '';
  static String get utilityName => _cachedUser?.utilityName ?? '';
  static int get utilityId => _cachedUser?.utilityId ?? 0;
  static int get substationId => _cachedUser?.substationId ?? 0;
  static bool get isSuperadmin => _cachedUser?.isSuperadmin ?? false;
  static String get sessionId => _cachedUser?.sessionId ?? '';

  // Permission Helpers
  static bool get isLoggedIn => _cachedUser != null;
  static bool get isAdmin => roleName.toLowerCase() == 'admin' || isSuperadmin;
  static bool get canManageUsers => isAdmin || isSuperadmin;
  static bool get canViewReports => isLoggedIn; // All logged in users can view reports
  static bool get canAssignTasks => isAdmin || designation.toLowerCase().contains('supervisor');
  static bool get hasValidSession => sessionId.isNotEmpty && isLoggedIn;

  // Utility Methods
  static String get displayName => fullName.isNotEmpty ? fullName : email;
  static String get roleDisplayName => roleName.isNotEmpty ? roleName : designation;
  static String get fullUserInfo => '$fullName ($designation) - $departmentName, $utilityName';

  /// Get complete session data as a map
  static Map<String, dynamic>? getCompleteSessionData() {
    if (_cachedUser == null) return null;
    return _cachedUser!.toJson();
  }

  /// Refresh session data from SharedPreferences
  static Future<Map<String, dynamic>?> refreshSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('user_data');
      if (userData != null) {
        final Map<String, dynamic> userJson = json.decode(userData);
        _cachedUser = UserModel.fromJson(userJson);
        return userJson;
      }
    } catch (e) {
      print('Error refreshing session data: $e');
    }
    return null;
  }

  /// Print session information for debugging
  static Future<void> printSessionInfo() async {
    await initialize();
    print('=== SESSION MANAGER INFO ===');
    print('Is Logged In: $isLoggedIn');
    print('User ID: $userId');
    print('Full Name: $fullName');
    print('Email: $email');
    print('Role: $roleName');
    print('Designation: $designation');
    print('Department: $departmentName');
    print('Utility: $utilityName ($utilityId)');
    print('Substation ID: $substationId');
    print('Is Superadmin: $isSuperadmin');
    print('Session ID: $sessionId');
    print('Is Admin: $isAdmin');
    print('Can Manage Users: $canManageUsers');
    print('============================');
  }
}