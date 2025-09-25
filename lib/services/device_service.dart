// services/device_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'session_manager.dart';

class DeviceService {
  static const String baseUrl = 'http://172.24.105.223:1001';

  /// Get substation connection details
  static Future<SubstationConnectionResponse?> getSubstationConnection(
    int utilityId, 
    int substationId
  ) async {
    try {
      // Check if user is logged in
      await SessionManager.initialize();
      if (!SessionManager.isLoggedIn) {
        throw Exception('Access denied: User not logged in');
      }

      // Get authentication headers
      final authHeaders = await AuthService.getAuthHeaders();
      // Override content type for GET request
      authHeaders['Content-Type'] = 'application/json';

      final response = await http.get(
        Uri.parse('$baseUrl/get_substation_connection/$utilityId/$substationId/'),
        headers: authHeaders,
      );

      print('Substation Connection API Response Status: ${response.statusCode}');
      print('Substation Connection API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SubstationConnectionResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // No connection found - this is not an error, just no existing data
        return null;
      } else {
        throw Exception('Failed to load substation connection: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching substation connection: $e');
      throw Exception('Failed to fetch substation connection: $e');
    }
  }

  /// Register a new device
  static Future<DeviceRegistrationResponse> registerDevice({
    required int substationId,
    required int feederId,
    required String macId,
    required double latitude,
    required double longitude,
    required String connectionType,
    required String ssid,
    required String simNumber,
    required String password,
    int? utilityId,  // Add utility ID parameter
  }) async {
    try {
      // Check if user is logged in
      await SessionManager.initialize();
      if (!SessionManager.isLoggedIn) {
        throw Exception('Access denied: User not logged in');
      }

      // Get authentication headers
      final authHeaders = await AuthService.getAuthHeaders();

      final Map<String, String> body = {
        'substation': substationId.toString(),
        'feeder': feederId.toString(),
        'mac_id': macId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'connection': connectionType,
        'ssid': ssid,  // Fixed: ensure SSID is included
        'sim_number': simNumber,
        'password': password,
        'utility_id': (utilityId ?? 0).toString(),  // Add utility_id to body
      };

      // Add CSRF token to body if available
      if (authHeaders.containsKey('X-CSRFToken')) {
        body['csrfmiddlewaretoken'] = authHeaders['X-CSRFToken']!;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/device/registeration/'),
        headers: authHeaders,
        body: body,
      );

      print('Device Registration API Request Body: $body');
      print('Device Registration API Response Status: ${response.statusCode}');
      print('Device Registration API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return DeviceRegistrationResponse.fromJson(jsonData);
      } else {
        // Handle error responses
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return DeviceRegistrationResponse(
            success: false,
            message: errorData['message'] ?? 'Device registration failed',
          );
        } catch (e) {
          return DeviceRegistrationResponse(
            success: false,
            message: 'Device registration failed with status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('Device registration error: $e');
      return DeviceRegistrationResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
      );
    }
  }
}

/// Response model for substation connection data
class SubstationConnectionResponse {
  final bool success;
  final List<SubstationConnection> connections;
  final String? message;

  SubstationConnectionResponse({
    required this.success,
    required this.connections,
    this.message,
  });

  factory SubstationConnectionResponse.fromJson(Map<String, dynamic> json) {
    return SubstationConnectionResponse(
      success: json['success'] ?? false,
      connections: json['connections'] != null
          ? (json['connections'] as List)
              .map((connection) => SubstationConnection.fromJson(connection))
              .toList()
          : [],
      message: json['message'],
    );
  }
}

/// Model for substation connection data
class SubstationConnection {
  final int substationId;
  final int utilityId;
  final String substationName;
  final String utilityName;
  final String connectionType;
  final String phoneNo;
  final String ssid;
  final String password;
  final double latitude;
  final double longitude;

  SubstationConnection({
    required this.substationId,
    required this.utilityId,
    required this.substationName,
    required this.utilityName,
    required this.connectionType,
    required this.phoneNo,
    required this.ssid,
    required this.password,
    required this.latitude,
    required this.longitude,
  });

  factory SubstationConnection.fromJson(Map<String, dynamic> json) {
    return SubstationConnection(
      substationId: json['substation_id'] ?? 0,
      utilityId: json['utility_id'] ?? 0,
      substationName: json['substation_name'] ?? '',
      utilityName: json['utility_name'] ?? '',
      connectionType: json['connection_type'] ?? '',
      phoneNo: json['phone_no'] ?? '',
      ssid: json['ssid'] ?? '',
      password: json['password'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }
  
  // Helper method to parse latitude/longitude that might come as strings
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

/// Response model for device registration
class DeviceRegistrationResponse {
  final bool success;
  final String message;

  DeviceRegistrationResponse({
    required this.success,
    required this.message,
  });

  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}