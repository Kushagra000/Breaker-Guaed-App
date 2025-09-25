// services/signup_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  
  /// Register a new user account
  static Future<SignupResponse> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required int designationId,
    required String password,
    required int roleId,
    required int departmentId,
    int? utilityId,
    int? substationId,
  }) async {
    try {
      final Map<String, String> formData = {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'designation_id': designationId.toString(),
        'password': password,
        'role_id': roleId.toString(),
        'department_id': departmentId.toString(),
      };

      // Add optional fields if provided
      if (utilityId != null) {
        formData['utility_id'] = utilityId.toString();
      }
      if (substationId != null) {
        formData['substation_id'] = substationId.toString();
      }

      print('Signup Request Data: $formData');

      final Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/request-login/'),
        headers: headers,
        body: formData,
      );

      print('Signup API Response Status: ${response.statusCode}');
      print('Signup API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SignupResponse.fromJson(jsonData);
      } else if (response.statusCode == 403 && response.body.contains('CSRF')) {
        // CSRF error - provide helpful message
        return SignupResponse(
          success: false,
          message: 'Registration temporarily unavailable. Please contact your administrator to enable account registration.',
          error: 'CSRF protection is enabled on the server. The backend needs to be configured to allow registration requests.',
        );
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return SignupResponse(
            success: false,
            message: jsonData['message'] ?? 'Registration failed',
            error: jsonData['error'],
          );
        } catch (e) {
          // If response is not JSON (like HTML error page)
          return SignupResponse(
            success: false,
            message: 'Registration failed. Please try again later.',
            error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      }
    } catch (e) {
      print('Error during signup: $e');
      return SignupResponse(
        success: false,
        message: 'Network error occurred. Please check your internet connection and try again.',
        error: e.toString(),
      );
    }
  }
}

class SignupResponse {
  final bool success;
  final String message;
  final int? userId;
  final String? error;

  SignupResponse({
    required this.success,
    required this.message,
    this.userId,
    this.error,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userId: json['user_id'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user_id': userId,
      'error': error,
    };
  }
}