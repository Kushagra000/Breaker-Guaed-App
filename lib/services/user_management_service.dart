// services/user_management_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_management_model.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class UserManagementService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Fetch users management data including users, pending users, and linemen
  static Future<UserManagementResponse?> getUsersData() async {
    try {
      await SessionManager.initialize();
      if (!SessionManager.isLoggedIn) {
        throw Exception('Access denied: User not logged in');
      }

      final authHeaders = await AuthService.getAuthHeaders();
      final headers = {
        'Content-Type': 'application/json',
        ...authHeaders,
      };

      final response = await http.get(
        Uri.parse('$baseUrl/manage_users/?format=json'),
        headers: headers,
      );

      print('Users Management API Response Status: ${response.statusCode}');
      print('Users Management API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserManagementResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load users data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users data: $e');
      throw Exception('Failed to fetch users data: $e');
    }
  }

  /// Approve a user by ID
  static Future<bool> approveUser(int userId) async {
    try {
      await SessionManager.initialize();
      if (!SessionManager.isLoggedIn) {
        throw Exception('Access denied: User not logged in');
      }

      final authHeaders = await AuthService.getAuthHeaders();
      final headers = {
        'Content-Type': 'application/json',
        ...authHeaders,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/approve-user/$userId/'),
        headers: headers,
      );

      print('Approve User API Response Status: ${response.statusCode}');
      print('Approve User API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      } else {
        throw Exception('Failed to approve user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error approving user: $e');
      return false;
    }
  }

  /// Reject a user by ID
  static Future<bool> rejectUser(int userId) async {
    try {
      await SessionManager.initialize();
      if (!SessionManager.isLoggedIn) {
        throw Exception('Access denied: User not logged in');
      }

      final authHeaders = await AuthService.getAuthHeaders();
      final headers = {
        'Content-Type': 'application/json',
        ...authHeaders,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/reject-user/$userId/'),
        headers: headers,
      );

      print('Reject User API Response Status: ${response.statusCode}');
      print('Reject User API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      } else {
        throw Exception('Failed to reject user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error rejecting user: $e');
      return false;
    }
  }

  /// Filter pending users by utility ID
  static List<UserData> filterPendingUsersByUtility(List<UserData> pendingUsers, int? utilityId) {
    if (utilityId == null || utilityId == 0) {
      return pendingUsers;
    }
    return pendingUsers.where((user) => user.utilityId == utilityId).toList();
  }
}