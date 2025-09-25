// services/utility_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/utility_hierarchy_model.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class UtilityService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Fetch utilities hierarchy data
  /// Accessible for all users (including non-authenticated for signup)
  static Future<UtilityHierarchyResponse?> getUtilitiesHierarchy({bool requireAuth = true}) async {
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
        Uri.parse('$baseUrl/utilities/hierarchy/'),
        headers: headers,
      );

      print('Utilities API Response Status: ${response.statusCode}');
      print('Utilities API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UtilityHierarchyResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load utilities hierarchy: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching utilities hierarchy: $e');
      throw Exception('Failed to fetch utilities hierarchy: $e');
    }
  }

  /// Check if current user has permission to access utilities data
  static Future<bool> checkUtilitiesPermission() async {
    try {
      await SessionManager.initialize();
      return SessionManager.isSuperadmin;
    } catch (e) {
      print('Error checking utilities permission: $e');
      return false;
    }
  }

  /// Get utility by ID from the hierarchy data
  static UtilityData? getUtilityById(List<UtilityData> utilities, int utilityId) {
    try {
      return utilities.firstWhere((utility) => utility.utilityId == utilityId);
    } catch (e) {
      return null;
    }
  }

  /// Get substation by ID from a utility's substations
  static SubstationData? getSubstationById(UtilityData utility, int substationId) {
    try {
      return utility.substations.firstWhere((substation) => substation.substationId == substationId);
    } catch (e) {
      return null;
    }
  }

  /// Get all substations from utilities hierarchy
  static List<SubstationData> getAllSubstations(List<UtilityData> utilities) {
    List<SubstationData> allSubstations = [];
    for (var utility in utilities) {
      allSubstations.addAll(utility.substations);
    }
    return allSubstations;
  }

  /// Filter substations by utility ID
  static List<SubstationData> getSubstationsByUtilityId(List<UtilityData> utilities, int utilityId) {
    final utility = getUtilityById(utilities, utilityId);
    return utility?.substations ?? [];
  }
}