// services/management_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/management_data_model.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class ManagementService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Fetch management data including roles, designations, and departments
  /// Accessible for all users (including non-authenticated for signup)
  static Future<ManagementDataResponse?> getManagementData({bool requireAuth = true}) async {
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      
      // Only add auth headers if authentication is required
      if (requireAuth) {
        await SessionManager.initialize();
        if (!SessionManager.isLoggedIn) {
          throw Exception('Access denied: User not logged in');
        }
        final authHeaders = await AuthService.getAuthHeaders();
        headers.addAll(authHeaders);
        headers['Content-Type'] = 'application/json'; // Override content type for GET request
      }

      final response = await http.get(
        Uri.parse('$baseUrl/manage/?format=json'),
        headers: headers,
      );

      print('Management API Response Status: ${response.statusCode}');
      print('Management API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ManagementDataResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load management data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching management data: $e');
      throw Exception('Failed to fetch management data: $e');
    }
  }

  /// Get role by ID from management data
  static RoleData? getRoleById(List<RoleData> roles, int roleId) {
    try {
      return roles.firstWhere((role) => role.roleId == roleId);
    } catch (e) {
      return null;
    }
  }

  /// Get designation by ID from management data
  static DesignationData? getDesignationById(List<DesignationData> designations, int designationId) {
    try {
      return designations.firstWhere((designation) => designation.designationId == designationId);
    } catch (e) {
      return null;
    }
  }

  /// Get department by ID from management data
  static DepartmentData? getDepartmentById(List<DepartmentData> departments, int departmentId) {
    try {
      return departments.firstWhere((department) => department.departmentId == departmentId);
    } catch (e) {
      return null;
    }
  }
}