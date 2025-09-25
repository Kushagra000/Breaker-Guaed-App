import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/session_manager.dart';

class UserProfile extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  
  String get username => _user?.fullName ?? '';
  String get email => _user?.email ?? '';
  String get designation => _user?.designation ?? '';
  String get roleName => _user?.roleName ?? '';
  String get departmentName => _user?.departmentName ?? '';
  String get utilityName => _user?.utilityName ?? '';
  int get utilityId => _user?.utilityId ?? 0;
  int get substationId => _user?.substationId ?? 0;
  bool get isSuperadmin => _user?.isSuperadmin ?? false;
  String get sessionId => _user?.sessionId ?? '';

  UserProfile() {
    _checkSavedSession();
  }

  // Check for saved session on app start
  Future<void> _checkSavedSession() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final savedUser = await AuthService.getSavedUser();
      if (savedUser != null) {
        _user = savedUser;
        _isLoggedIn = true;
        // Sync with SessionManager
        SessionManager.updateUser(savedUser);
      }
    } catch (e) {
      print('Error checking saved session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<LoginResponse> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await AuthService.login(email, password);
      
      if (response.success && response.user != null) {
        _user = response.user;
        _isLoggedIn = true;
        // Sync with SessionManager
        SessionManager.updateUser(response.user!);
      }
      
      return response;
    } catch (e) {
      print('Login error in provider: $e');
      return LoginResponse(
        success: false,
        message: 'Login failed: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await AuthService.logout();
      _user = null;
      _isLoggedIn = false;
      // Sync with SessionManager
      SessionManager.clear();
    } catch (e) {
      print('Logout error in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile (for compatibility with existing code)
  void updateProfile({
    required String username,
    required String email,
    required String mobile,
    required String designation,
  }) {
    // This method is kept for backward compatibility
    // In practice, user data should come from the server
    notifyListeners();
  }

  // Clear user data
  void clearUser() {
    _user = null;
    _isLoggedIn = false;
    SessionManager.clear();
    notifyListeners();
  }
}
