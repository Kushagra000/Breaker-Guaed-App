// services/work_history_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/work_history_model.dart';
import 'session_manager.dart';
import 'auth_service.dart';

class WorkHistoryService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Fetch work history data including shutdowns, substations, feeders, and JEs
  static Future<WorkHistoryResponse?> getWorkHistory() async {
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
        Uri.parse('$baseUrl/work_history/?format=json'),
        headers: headers,
      );

      print('Work History API Response Status: ${response.statusCode}');
      print('Work History API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return WorkHistoryResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load work history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching work history: $e');
      throw Exception('Failed to fetch work history: $e');
    }
  }

  /// Filter shutdowns by utility ID
  static List<ShutdownData> filterShutdownsByUtility(List<ShutdownData> shutdowns, int? utilityId) {
    if (utilityId == null || utilityId == 0) {
      return shutdowns;
    }
    return shutdowns.where((shutdown) => shutdown.utilityId == utilityId).toList();
  }

  /// Filter shutdowns by substation ID
  static List<ShutdownData> filterShutdownsBySubstation(List<ShutdownData> shutdowns, int? substationId) {
    if (substationId == null || substationId == 0) {
      return shutdowns;
    }
    return shutdowns.where((shutdown) => shutdown.substationId == substationId).toList();
  }

  /// Get shutdown status color based on status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Format date time string for display
  static String formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }
}