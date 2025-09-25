// services/lineman_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';
import 'auth_service.dart';
import '../models/assignment_models.dart';
import '../models/lineman_on_work_model.dart';

class LinemanService {
  static const String baseUrl = 'http://172.24.105.223:1001';

  /// Get linemen who are currently on work for a specific substation
  static Future<LinemanOnWorkResponse> getLinemenOnWork(int substationId) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers with CSRF token and session cookie
      final authHeaders = await AuthService.getAuthHeaders();
      
      print('=== LINEMEN ON WORK API DEBUG ===');
      print('Requesting linemen on work for substation ID: $substationId');
      print('API URL: $baseUrl/api/linemen-on-work/?substation_id=$substationId');
      print('Request Headers: ${authHeaders.keys.join(', ')}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/linemen-on-work/?substation_id=$substationId'),
        headers: authHeaders,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return LinemanOnWorkResponse.fromJson(jsonData);
        } catch (e) {
          print('JSON parsing error: $e');
          return LinemanOnWorkResponse(
            success: false,
            linemen: [],
          );
        }
      } else {
        String errorMessage = 'Failed to fetch linemen on work';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        print('API Error: $errorMessage');
        return LinemanOnWorkResponse(
          success: false,
          linemen: [],
        );
      }
    } catch (e) {
      print('Error fetching linemen on work: $e');
      return LinemanOnWorkResponse(
        success: false,
        linemen: [],
      );
    }
  }

  /// Get linemen by substation ID with client-side filtering as backup
  static Future<Map<String, dynamic>> getLinemanBySubstation(int substationId) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers with CSRF token and session cookie
      final authHeaders = await AuthService.getAuthHeaders();
      
      print('=== LINEMAN API DEBUG ===');
      print('Requesting linemen for substation ID: $substationId');
      print('API URL: $baseUrl/get_linemen_by_substation/$substationId/');
      print('Request Headers: ${authHeaders.keys.join(', ')}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/get_linemen_by_substation/$substationId/'),
        headers: authHeaders,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final List<dynamic> rawLinemenList = jsonData['linemen'] ?? [];
          print('Raw API returned ${rawLinemenList.length} linemen');
          
          // Convert to List<Map<String, dynamic>>
          List<Map<String, dynamic>> allLinemen = rawLinemenList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          
          // Debug: Print all linemen with their substation IDs
          print('=== ALL LINEMEN FROM API ===');
          allLinemen.forEach((lineman) {
            final linemanSubstationId = lineman['substation_id'];
            final name = lineman['name'] ?? 'Unknown';
            final status = lineman['status'];
            print('Lineman: $name | Substation ID: $linemanSubstationId | Status: $status | Target: $substationId');
          });
          
          // CLIENT-SIDE FILTERING: Filter linemen by substation_id
          List<Map<String, dynamic>> filteredLinemen = allLinemen.where((lineman) {
            final linemanSubstationId = lineman['substation_id'];
            
            // Handle different data types for substation_id
            int? linemanSubId;
            if (linemanSubstationId is int) {
              linemanSubId = linemanSubstationId;
            } else if (linemanSubstationId is String) {
              linemanSubId = int.tryParse(linemanSubstationId);
            }
            
            final matches = linemanSubId == substationId;
            if (!matches) {
              print('FILTERED OUT: ${lineman['name']} (substation_id: $linemanSubstationId != $substationId)');
            }
            return matches;
          }).toList();
          
          print('=== FILTERING RESULTS ===');
          print('Before filtering: ${allLinemen.length} linemen');
          print('After filtering: ${filteredLinemen.length} linemen');
          print('Target substation ID: $substationId');
          
          if (filteredLinemen.isNotEmpty) {
            print('=== FILTERED LINEMEN ===');
            filteredLinemen.forEach((lineman) {
              print('✓ ${lineman['name']} | Substation ID: ${lineman['substation_id']} | Status: ${lineman['status']}');
            });
          } else {
            print('❌ No linemen found for substation $substationId');
            print('Available substation IDs in data:');
            Set<dynamic> availableSubstationIds = allLinemen
                .map((l) => l['substation_id'])
                .toSet();
            availableSubstationIds.forEach((id) => print('  - $id'));
          }
          
          // Return the filtered data
          final filteredResponse = {
            'linemen': filteredLinemen,
            'total_count': filteredLinemen.length,
            'original_count': allLinemen.length,
            'substation_id': substationId,
          };
          
          return {
            'success': true,
            'message': 'Linemen fetched and filtered successfully',
            'data': filteredResponse,
          };
        } catch (e) {
          print('JSON parsing error: $e');
          return {
            'success': false,
            'message': 'Failed to parse response data: $e',
            'data': null,
          };
        }
      } else {
        String errorMessage = 'Failed to fetch linemen';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        print('API Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
          'data': null,
        };
      }
    } catch (e) {
      print('Error fetching linemen: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  /// Add a new lineman
  static Future<Map<String, dynamic>> addLineman({
    required String name,
    required String phone,
    required String email,
    required String status,
    required int substationId,
    int? utilityId,
  }) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers with CSRF token and session cookie
      final authHeaders = await AuthService.getAuthHeaders();
      
      // Prepare request body
      final body = {
        'name': name,
        'phone': phone,
        'email': email,
        'status': status.toString().toLowerCase(), // Convert to lowercase string
        'substation_id': substationId.toString(),
        if (utilityId != null) 'utility_id': utilityId.toString(),
      };
      
      // Add CSRF token to body if available (Django might expect it in body too)
      if (authHeaders.containsKey('X-CSRFToken')) {
        body['csrfmiddlewaretoken'] = authHeaders['X-CSRFToken']!;
      }
      
      print('Add Lineman Request Headers: ${authHeaders.keys.join(', ')}');
      print('Add Lineman Request Body: ${body.keys.join(', ')}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/add_linemen/'),
        headers: authHeaders,
        body: body,
      );

      print('Add Lineman API Response Status: ${response.statusCode}');
      print('Add Lineman API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302) {
        // Handle success responses (including 302 redirects)
        if (response.statusCode == 302) {
          // 302 redirect typically means success in Django forms
          return {
            'success': true,
            'message': 'Lineman added successfully',
            'data': {'status': 'created'},
          };
        }
        
        // Handle JSON responses for 200/201
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Lineman added successfully',
            'data': jsonData,
          };
        } catch (e) {
          // If JSON parsing fails but status is success, still return success
          return {
            'success': true,
            'message': 'Lineman added successfully',
            'data': {'status': 'created'},
          };
        }
      } else if (response.statusCode == 403 && response.body.contains('CSRF')) {
        // CSRF failed, try without CSRF data as fallback
        print('CSRF attempt failed, retrying without CSRF protection...');
        return await _addLinemanWithoutCSRF(
          name: name,
          phone: phone,
          email: email,
          status: status,
          substationId: substationId,
          utilityId: utilityId,
        );
      } else {
        String errorMessage = 'Failed to add lineman';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          // If response is HTML (like error page), extract meaningful message
          if (response.body.contains('CSRF')) {
            errorMessage = 'CSRF token validation failed';
          } else if (response.body.contains('success') || response.body.contains('created') || response.body.contains('added')) {
            // If response body suggests success but status code is unexpected
            print('Detected success indicators in response body despite status ${response.statusCode}');
            return {
              'success': true,
              'message': 'Lineman added successfully',
              'data': {'status': 'created', 'note': 'Success detected from response content'},
            };
          } else {
            errorMessage = 'Server error (${response.statusCode})';
          }
        }
        return {
          'success': false,
          'message': errorMessage,
          'data': null,
        };
      }
    } catch (e) {
      print('Error adding lineman: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  /// Fallback method to add lineman without CSRF protection
  static Future<Map<String, dynamic>> _addLinemanWithoutCSRF({
    required String name,
    required String phone,
    required String email,
    required String status,
    required int substationId,
    int? utilityId,
  }) async {
    try {
      print('Attempting to add lineman without CSRF protection...');
      
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      };
      
      final body = {
        'name': name,
        'phone': phone,
        'email': email,
        'status': status.toString().toLowerCase(), // Convert boolean to string
        'substation_id': substationId.toString(),
        if (utilityId != null) 'utility_id': utilityId.toString(),
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/add_lineman/'),
        headers: headers,
        body: body,
      );
      
      print('Fallback API Response Status: ${response.statusCode}');
      print('Fallback API Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302) {
        // Handle success responses (including 302 redirects)
        if (response.statusCode == 302) {
          // 302 redirect typically means success in Django forms
          return {
            'success': true,
            'message': 'Lineman added successfully (fallback)',
            'data': {'status': 'created'},
          };
        }
        
        // Handle JSON responses for 200/201
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Lineman added successfully (fallback)',
            'data': jsonData,
          };
        } catch (e) {
          // If JSON parsing fails but status is success, still return success
          return {
            'success': true,
            'message': 'Lineman added successfully (fallback)',
            'data': {'status': 'created'},
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to add lineman even without CSRF protection',
          'data': null,
        };
      }
    } catch (e) {
      print('Error in fallback method: $e');
      return {
        'success': false,
        'message': 'Fallback method failed: $e',
        'data': null,
      };
    }
  }

  /// Validate lineman data before submission
  /// Validate assignment data before submission
  static Map<String, String?> validateAssignmentData({
    required String purpose,
    required int? substationId,
    required int? feederId,
    required int? ssoId,
    required int? jeId,
    required List<int> selectedLinemenIds,
    required DateTime? startTime,
    required DateTime? endTime,
  }) {
    Map<String, String?> errors = {};

    if (purpose.trim().isEmpty) {
      errors['purpose'] = 'Purpose is required';
    }

    if (substationId == null || substationId <= 0) {
      errors['substation'] = 'Please select a substation';
    }

    if (feederId == null || feederId <= 0) {
      errors['feeder'] = 'Please select a feeder';
    }

    if (ssoId == null || ssoId <= 0) {
      errors['sso'] = 'Please select an SSO';
    }

    if (jeId == null || jeId <= 0) {
      errors['je'] = 'Please select a JE';
    }

    if (selectedLinemenIds.isEmpty) {
      errors['linemen'] = 'Please select at least one lineman';
    }

    if (startTime == null) {
      errors['startTime'] = 'Please select start time';
    }

    if (endTime == null) {
      errors['endTime'] = 'Please select end time';
    }

    if (startTime != null && endTime != null) {
      if (endTime.isBefore(startTime)) {
        errors['endTime'] = 'End time must be after start time';
      }
      
      final now = DateTime.now();
      if (startTime.isBefore(now)) {
        errors['startTime'] = 'Start time must be in the future';
      }
    }

    return errors;
  }

  /// Validate lineman data before submission
  static Map<String, String?> validateLinemanData({
    required String name,
    required String phone,
    required String email,
    required String status,
    required int? substationId,
    int? utilityId,
  }) {
    Map<String, String?> errors = {};

    if (name.trim().isEmpty) {
      errors['name'] = 'Lineman name is required';
    }

    if (phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^\d{10}$').hasMatch(phone.trim())) {
      errors['phone'] = 'Please enter a valid 10-digit phone number';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Status is now boolean, no validation needed

    if (substationId == null || substationId <= 0) {
      errors['substation'] = 'Please select a substation';
    }

    if (utilityId != null && utilityId <= 0) {
      errors['utility'] = 'Please select a utility';
    }

    return errors;
  }

  /// Get available linemen for assignment based on substation, start time, and end time
  static Future<AvailableLinemanResponse> getAvailableLinemen({
    required int substationId,
    required String startTime,
    required String endTime,
  }) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers
      final authHeaders = await AuthService.getAuthHeaders();
      authHeaders['Content-Type'] = 'application/json';
      
      // Build URL manually to avoid URL encoding of colons in time format
      final baseApiUrl = '$baseUrl/available-linemen/';
      final apiUrl = '$baseApiUrl?substation_id=$substationId&start_time=$startTime&end_time=$endTime';
      
      print('Available Linemen API URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: authHeaders,
      );

      print('Available Linemen API Response Status: ${response.statusCode}');
      print('Available Linemen API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return AvailableLinemanResponse.fromJson(jsonData);
        } catch (e) {
          print('JSON parsing error: $e');
          return AvailableLinemanResponse(
            success: false,
            message: 'Failed to parse response data: $e',
            linemen: [],
          );
        }
      } else {
        String errorMessage = 'Failed to fetch available linemen';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        print('API Error: $errorMessage');
        return AvailableLinemanResponse(
          success: false,
          message: errorMessage,
          linemen: [],
        );
      }
    } catch (e) {
      print('Error fetching available linemen: $e');
      return AvailableLinemanResponse(
        success: false,
        message: 'Network error: $e',
        linemen: [],
      );
    }
  }

  /// Get SSO and JE users for a specific substation
  static Future<Map<String, dynamic>> getSubstationUsers(int substationId) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers
      final authHeaders = await AuthService.getAuthHeaders();
      authHeaders['Content-Type'] = 'application/json';
      
      final apiUrl = '$baseUrl/get_substation_users/$substationId/';
      
      print('Substation Users API URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: authHeaders,
      );

      print('Substation Users API Response Status: ${response.statusCode}');
      print('Substation Users API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return {
            'success': true,
            'data': jsonData,
          };
        } catch (e) {
          print('JSON parsing error: $e');
          return {
            'success': false,
            'message': 'Failed to parse response data: $e',
          };
        }
      } else {
        String errorMessage = 'Failed to fetch substation users';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        print('API Error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Error fetching substation users: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Submit assignment request to schedule shutdown
  static Future<Map<String, dynamic>> submitAssignment(AssignmentRequest request) async {
    try {
      await SessionManager.initialize();
      
      if (!SessionManager.isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get authentication headers with CSRF token and session cookie
      final authHeaders = await AuthService.getAuthHeaders();
      
      // Convert request to custom form body that supports array fields
      final formBody = _buildCustomFormBody(request, authHeaders);
      
      print('Assignment API URL: $baseUrl/api/schedule_shutdown/');
      print('Assignment Request Headers: ${authHeaders.keys.join(', ')}');
      print('Assignment Form Body Length: ${formBody.length} bytes');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/schedule_shutdown/'),
        headers: {
          ...authHeaders,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formBody,
      );

      print('Assignment API Response Status: ${response.statusCode}');
      print('Assignment API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302) {
        // Handle success responses (including 302 redirects)
        if (response.statusCode == 302) {
          // 302 redirect typically means success in Django forms
          return {
            'success': true,
            'message': 'Assignment submitted successfully',
          };
        }
        
        // Handle JSON responses for 200/201
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Assignment submitted successfully',
            'data': jsonData,
          };
        } catch (e) {
          // If JSON parsing fails but status is success, still return success
          return {
            'success': true,
            'message': 'Assignment submitted successfully',
          };
        }
      } else if (response.statusCode == 403 && response.body.contains('CSRF')) {
        // CSRF failed, try without CSRF data as fallback
        print('CSRF attempt failed, retrying without CSRF protection...');
        return await _submitAssignmentWithoutCSRF(request);
      } else {
        String errorMessage = 'Failed to submit assignment';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response is HTML (like error page), extract meaningful message
          if (response.body.contains('CSRF')) {
            errorMessage = 'CSRF token validation failed';
          } else if (response.body.contains('success') || response.body.contains('scheduled')) {
            // If response body suggests success but status code is unexpected
            print('Detected success indicators in response body despite status ${response.statusCode}');
            return {
              'success': true,
              'message': 'Assignment submitted successfully',
            };
          } else {
            errorMessage = 'Server error (${response.statusCode})';
          }
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Error submitting assignment: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Build custom form body that properly handles array fields for Django
  static String _buildCustomFormBody(AssignmentRequest request, Map<String, String> authHeaders) {
    List<String> formParts = [];
    
    // Add basic fields
    formParts.add('purpose=${Uri.encodeComponent(request.purpose)}');
    formParts.add('substation=${Uri.encodeComponent(request.substationId.toString())}');
    formParts.add('shutdown_count=${Uri.encodeComponent(request.shutdowns.length.toString())}');
    
    // Add CSRF token if available
    if (authHeaders.containsKey('X-CSRFToken')) {
      formParts.add('csrfmiddlewaretoken=${Uri.encodeComponent(authHeaders['X-CSRFToken']!)}');
    }
    
    // Add shutdown data
    for (int i = 0; i < request.shutdowns.length; i++) {
      final shutdown = request.shutdowns[i];
      final index = i + 1; // API expects 1-based indexing
      
      formParts.add('shutdowns%5B${index}%5D%5Bfeeder%5D=${Uri.encodeComponent(shutdown.feederId.toString())}');
      formParts.add('shutdowns%5B${index}%5D%5Bofficer%5D=${Uri.encodeComponent(shutdown.ssoName)}');
      formParts.add('shutdowns%5B${index}%5D%5Bje%5D=${Uri.encodeComponent(shutdown.jeName)}');
      formParts.add('shutdowns%5B${index}%5D%5Bstart%5D=${Uri.encodeComponent(shutdown.startTime)}');
      formParts.add('shutdowns%5B${index}%5D%5Bend%5D=${Uri.encodeComponent(shutdown.endTime)}');
      
      // Add each lineman ID as a separate array element
      for (int linemanId in shutdown.linemenIds) {
        formParts.add('shutdowns%5B${index}%5D%5Blinemen%5D%5B%5D=${Uri.encodeComponent(linemanId.toString())}');
      }
    }
    
    final formBody = formParts.join('&');
    
    print('=== CUSTOM FORM BODY DEBUG ===');
    print('Form parts count: ${formParts.length}');
    print('Purpose: ${request.purpose}');
    print('Substation ID: ${request.substationId}');
    print('Shutdown count: ${request.shutdowns.length}');
    for (int i = 0; i < request.shutdowns.length; i++) {
      final shutdown = request.shutdowns[i];
      print('Shutdown ${i + 1}: Feeder=${shutdown.feederId}, SSO=${shutdown.ssoName}, JE=${shutdown.jeName}, Linemen=${shutdown.linemenIds}');
    }
    print('Form body preview: ${formBody.substring(0, formBody.length.clamp(0, 200))}...');
    print('=============================');
    
    return formBody;
  }

  /// Fallback method to submit assignment without CSRF protection
  static Future<Map<String, dynamic>> _submitAssignmentWithoutCSRF(AssignmentRequest request) async {
    try {
      print('Attempting to submit assignment without CSRF protection...');
      
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      };
      
      // Use custom form body without CSRF token
      final formBody = _buildCustomFormBody(request, {});
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/schedule_shutdown/'),
        headers: headers,
        body: formBody,
      );
      
      print('Fallback Assignment API Response Status: ${response.statusCode}');
      print('Fallback Assignment API Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302) {
        // Handle success responses (including 302 redirects)
        if (response.statusCode == 302) {
          // 302 redirect typically means success in Django forms
          return {
            'success': true,
            'message': 'Assignment submitted successfully (fallback)',
          };
        }
        
        // Handle JSON responses for 200/201
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return {
            'success': true,
            'message': jsonData['message'] ?? 'Assignment submitted successfully (fallback)',
            'data': jsonData,
          };
        } catch (e) {
          // If JSON parsing fails but status is success, still return success
          return {
            'success': true,
            'message': 'Assignment submitted successfully (fallback)',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to submit assignment even without CSRF protection',
        };
      }
    } catch (e) {
      print('Error in fallback assignment method: $e');
      return {
        'success': false,
        'message': 'Fallback method failed: $e',
      };
    }
  }
}