import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'session_manager.dart';

class AuthService {
  static const String baseUrl = 'http://172.24.105.223:1001';
  static const String loginEndpoint = '/login/';
  
  // Store session cookies and CSRF data globally
  static String? _sessionCookie;
  static String? _csrfToken;
  static String? _csrfCookie;

  // Initialize session by making a GET request to login page to get CSRF data
  static Future<void> _initializeSession() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter App)',
        },
      );
      
      print('Session Init Status: ${response.statusCode}');
      print('Session Init Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        // Extract complete CSRF data (both token and cookie)
        final csrfData = _getCsrfData(response.body, response.headers);
        if (csrfData['token'] != null) {
          _csrfToken = csrfData['token'];
          print('Extracted CSRF token from HTML: $_csrfToken');
        }
        if (csrfData['cookie'] != null) {
          _csrfCookie = csrfData['cookie'];
          print('Extracted CSRF cookie: $_csrfCookie');
        }
        
        // Extract session cookie if present
        final sessionCookie = _extractSessionCookie(response.headers);
        if (sessionCookie != null) {
          _sessionCookie = sessionCookie;
          print('Extracted initial session cookie: $_sessionCookie');
        }
      }
    } catch (e) {
      print('Error initializing session: $e');
    }
  }
  
  // Extract both CSRF token and cookie for complete CSRF protection
  static Map<String, String?> _getCsrfData(String html, Map<String, String> headers) {
    final result = <String, String?>{};
    
    try {
      // Extract CSRF token from HTML form field
      final pattern = 'name="csrfmiddlewaretoken" value="';
      final startIndex = html.indexOf(pattern);
      if (startIndex != -1) {
        final valueStart = startIndex + pattern.length;
        final valueEnd = html.indexOf('"', valueStart);
        if (valueEnd != -1) {
          result['token'] = html.substring(valueStart, valueEnd);
          print('Found CSRF token in HTML: ${result['token']}');
        }
      }
      
      // Extract CSRF cookie from Set-Cookie header
      final setCookie = headers['set-cookie'] ?? '';
      final csrfCookiePattern = 'csrftoken=';
      final cookieStart = setCookie.indexOf(csrfCookiePattern);
      if (cookieStart != -1) {
        final valueStart = cookieStart + csrfCookiePattern.length;
        final valueEnd = setCookie.indexOf(';', valueStart);
        final endIndex = valueEnd != -1 ? valueEnd : setCookie.length;
        result['cookie'] = setCookie.substring(valueStart, endIndex);
        print('Found CSRF cookie in headers: ${result['cookie']}');
      }
      
      if (result['token'] == null || result['cookie'] == null) {
        print('Warning: Incomplete CSRF data - token: ${result['token'] != null}, cookie: ${result['cookie'] != null}');
      }
    } catch (e) {
      print('Error extracting CSRF data: $e');
    }
    
    return result;
  }

  // Login method
  static Future<LoginResponse> login(String email, String password) async {
    try {
      // First, get a session and CSRF token by making a simple GET request
      await _initializeSession();
      
      final Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'application/json',
      };
      
      // Add session cookie if available from initialization
      if (_sessionCookie != null) {
        headers['Cookie'] = 'sessionid=$_sessionCookie';
      }
      
      // Add CSRF token if available
      if (_csrfToken != null) {
        headers['X-CSRFToken'] = _csrfToken!;
      }
      
      final Map<String, String> body = {
        'email': email,
        'password': password,
      };
      
      // Add CSRF token to body as well
      if (_csrfToken != null) {
        body['csrfmiddlewaretoken'] = _csrfToken!;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: headers,
        body: body,
      );

      print('Login Request URL: $baseUrl$loginEndpoint');
      print('Login Request Headers: $headers');
      print('Login Request Body keys: ${body.keys.join(', ')}');
      print('Login Response Status: ${response.statusCode}');
      print('Login Response Headers: ${response.headers}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);
        
        if (loginResponse.success && loginResponse.user != null) {
          // Extract and store session cookie from login response
          final sessionCookie = _extractSessionCookie(response.headers);
          if (sessionCookie != null) {
            _sessionCookie = sessionCookie;
            print('Updated session cookie from login: $_sessionCookie');
            
            // Update user with the session cookie
            final user = loginResponse.user!.copyWith(sessionId: sessionCookie);
            await _saveUserSession(user);
            await _saveAuthTokens(sessionCookie, _csrfToken, _csrfCookie);
            SessionManager.updateUser(user);
            
            return LoginResponse(
              success: loginResponse.success,
              message: loginResponse.message,
              redirectUrl: loginResponse.redirectUrl,
              user: user,
            );
          } else {
            // Fallback to original session ID from response
            await _saveUserSession(loginResponse.user!);
            await _saveAuthTokens(loginResponse.user!.sessionId, _csrfToken, _csrfCookie);
            SessionManager.updateUser(loginResponse.user!);
          }
        }
        
        return loginResponse;
      } else {
        // Handle error responses
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          return LoginResponse(
            success: false,
            message: errorData['message'] ?? 'Login failed',
          );
        } catch (e) {
          return LoginResponse(
            success: false,
            message: 'Login failed with status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      return LoginResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
      );
    }
  }

  // Extract session cookie from response headers
  static String? _extractSessionCookie(Map<String, String> headers) {
    final setCookie = headers['set-cookie'];
    if (setCookie != null) {
      final cookies = setCookie.split(';');
      for (String cookie in cookies) {
        if (cookie.trim().startsWith('sessionid=')) {
          return cookie.trim().substring('sessionid='.length);
        }
      }
    }
    return null;
  }

  // Save authentication tokens and cookies
  static Future<void> _saveAuthTokens(String? sessionCookie, String? csrfToken, String? csrfCookie) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionCookie != null) {
      await prefs.setString('session_cookie', sessionCookie);
      _sessionCookie = sessionCookie;
    }
    if (csrfToken != null) {
      await prefs.setString('csrf_token', csrfToken);
      _csrfToken = csrfToken;
    }
    if (csrfCookie != null) {
      await prefs.setString('csrf_cookie', csrfCookie);
      _csrfCookie = csrfCookie;
    }
  }

  // Load authentication tokens
  static Future<void> _loadAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
    _csrfToken = prefs.getString('csrf_token');
    _csrfCookie = prefs.getString('csrf_cookie');
  }

  // Get stored authentication headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    await _loadAuthTokens();
    
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    
    // Build cookie header with both session and CSRF cookies
    final cookies = <String>[];
    if (_sessionCookie != null) {
      cookies.add('sessionid=$_sessionCookie');
      print('Added session cookie: sessionid=$_sessionCookie');
    }
    if (_csrfCookie != null) {
      cookies.add('csrftoken=$_csrfCookie');
      print('Added CSRF cookie: csrftoken=$_csrfCookie');
    }
    
    if (cookies.isNotEmpty) {
      headers['Cookie'] = cookies.join('; ');
    } else {
      print('Warning: No cookies available for API request');
    }
    
    if (_csrfToken != null) {
      headers['X-CSRFToken'] = _csrfToken!;
      print('Added CSRF token to headers: X-CSRFToken=$_csrfToken');
    } else {
      print('Warning: No CSRF token available for API request');
    }
    
    print('Complete auth headers: ${headers.keys.join(', ')}');
    return headers;
  }

  // Save user session data
  static Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('session_id', user.sessionId);
  }

  // Get saved user session
  static Future<UserModel?> getSavedUser() async {
    try {
      // Load authentication tokens first
      await _loadAuthTokens();
      
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final String? userData = prefs.getString('user_data');
        if (userData != null) {
          final Map<String, dynamic> userJson = json.decode(userData);
          final user = UserModel.fromJson(userJson);
          // Update SessionManager cache
          SessionManager.updateUser(user);
          print('Restored user session: ${user.fullName} with tokens: session=${_sessionCookie != null}, csrf_token=${_csrfToken != null}, csrf_cookie=${_csrfCookie != null}');
          return user;
        }
      }
      return null;
    } catch (e) {
      print('Error getting saved user: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Logout and clear session
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('is_logged_in');
      await prefs.remove('session_id');
      await prefs.remove('session_cookie');
      await prefs.remove('csrf_token');
      await prefs.remove('csrf_cookie');
      await prefs.clear();
      
      // Clear static variables
      _sessionCookie = null;
      _csrfToken = null;
      _csrfCookie = null;
      
      // Clear SessionManager cache
      SessionManager.clear();
      print('User session and auth tokens cleared');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Get session ID
  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }
}