// services/activity_logs_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity_log_model.dart';
import '../models/utility_hierarchy_model.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class ActivityLogsService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Fetch ALL activity logs (no server-side filtering)
  /// Frontend will handle all filtering and pagination
  static Future<ActivityLogResponse?> getAllActivityLogs() async {
    try {
      await SessionManager.initialize();
      
      // Check if user has admin access
      if (!SessionManager.isAdmin && !SessionManager.isSuperadmin) {
        throw Exception('Access denied: Only admin and super admin users can view activity logs');
      }

      Map<String, String> headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Simple API call - get ALL data, no query parameters
      final response = await http.get(
        Uri.parse('$baseUrl/activity-logs/'),
        headers: headers,
      );

      print('Activity Logs API Response Status: ${response.statusCode}');
      print('Activity Logs API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final activityResponse = ActivityLogResponse.fromJson(jsonData);
        print('Successfully parsed ${activityResponse.logs.length} activity logs');
        return activityResponse;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: Insufficient permissions');
      } else {
        throw Exception('Failed to load activity logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
      throw Exception('Failed to fetch activity logs: $e');
    }
  }

  /// Check if current user has permission to view activity logs
  static Future<bool> canViewActivityLogs() async {
    try {
      await SessionManager.initialize();
      return SessionManager.isAdmin || SessionManager.isSuperadmin;
    } catch (e) {
      print('Error checking activity logs permission: $e');
      return false;
    }
  }

  /// Check if user can filter by all utilities (super admin only)
  static bool canFilterAllUtilities() {
    try {
      return SessionManager.isSuperadmin;
    } catch (e) {
      return false;
    }
  }

  /// Get user's utility name for filtering
  static String getUserUtilityName() {
    try {
      return SessionManager.utilityName;
    } catch (e) {
      print('Error getting user utility name: $e');
      return '';
    }
  }
}