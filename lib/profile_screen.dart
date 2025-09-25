import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_provider.dart';
import 'services/session_manager.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? sessionData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }
  
  Future<void> _loadSessionData() async {
    await SessionManager.initialize();
    final data = SessionManager.getCompleteSessionData();
    setState(() {
      sessionData = data;
      isLoading = false;
    });
  }
  
  Future<void> _refreshSession() async {
    setState(() {
      isLoading = true;
    });
    
    final refreshedData = await SessionManager.refreshSessionData();
    if (refreshedData != null) {
      // Update the provider as well
      final userProfile = Provider.of<UserProfile>(context, listen: false);
      // Trigger a rebuild of provider
      userProfile.notifyListeners();
    }
    
    await _loadSessionData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshSession,
            tooltip: 'Refresh Session Data',
          ),
          Consumer<UserProfile>(
            builder: (context, userProfile, child) {
              return IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _handleLogout(context, userProfile),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<UserProfile>(
              builder: (context, userProfile, child) {
                if (!userProfile.isLoggedIn || userProfile.user == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No user data available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _handleLogout(context, userProfile),
                          child: Text('Go to Login'),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user display info
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue.shade900,
                                    child: Text(
                                      SessionManager.displayName.isNotEmpty
                                          ? SessionManager.displayName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          SessionManager.displayName,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          SessionManager.roleDisplayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (SessionManager.fullUserInfo.isNotEmpty)
                                          Text(
                                            SessionManager.fullUserInfo,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Session Information from Provider
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildInfoRow('User ID', SessionManager.userId?.toString() ?? 'N/A'),
                              _buildInfoRow('Full Name', SessionManager.fullName),
                              _buildInfoRow('Email', SessionManager.email),
                              _buildInfoRow('Role', SessionManager.roleName),
                              _buildInfoRow('Designation', SessionManager.designation),
                              _buildInfoRow('Department', SessionManager.departmentName),
                              _buildInfoRow('Utility', SessionManager.utilityName),
                              _buildInfoRow('Utility ID', SessionManager.utilityId.toString()),
                              _buildInfoRow('Super Admin', SessionManager.isSuperadmin ? 'Yes' : 'No'),
                              // _buildInfoRow('Session ID', SessionManager.sessionId),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Permission Information
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Permissions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildPermissionRow('Can Manage Users', SessionManager.canManageUsers),
                              _buildPermissionRow('Can View Reports', SessionManager.canViewReports),
                              _buildPermissionRow('Can Assign Tasks', SessionManager.canAssignTasks),
                              _buildPermissionRow('Is Admin', SessionManager.isAdmin),
                              _buildPermissionRow('Has Valid Session', SessionManager.hasValidSession),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Session Data from SessionManager
                
                      
                      SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await SessionManager.printSessionInfo();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Session info printed to console'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              icon: Icon(Icons.info),
                              label: Text('Print Session Info'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showLogoutConfirmation(context, userProfile),
                              icon: Icon(Icons.logout),
                              label: Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey[400] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionRow(String label, bool hasPermission) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, UserProfile userProfile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout(context, userProfile);
            },
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, UserProfile userProfile) async {
    await userProfile.logout();
    
    // Navigate to login and clear navigation stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }
}