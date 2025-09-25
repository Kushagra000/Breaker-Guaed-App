import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_management_model.dart';
import 'models/utility_hierarchy_model.dart';
import 'services/user_management_service.dart';
import 'services/utility_service.dart';
import 'user_profile_provider.dart';

class ApproveRejectScreen extends StatefulWidget {
  @override
  State<ApproveRejectScreen> createState() => _ApproveRejectScreenState();
}

class _ApproveRejectScreenState extends State<ApproveRejectScreen> {
  List<UserData> pendingUsers = [];
  List<UtilityData> utilities = [];
  int? selectedUtilityId;
  bool isLoading = true;
  bool isUtilityLocked = false;
  String? errorMessage;
  bool hasAccessDenied = false;

  // Helper method to check if user has admin privileges
  bool _hasAdminAccess(UserProfile userProfile) {
    final roleName = userProfile.roleName.toLowerCase();
    final isSuperadmin = userProfile.isSuperadmin;
    
    // Check if user is Super Admin or has Admin role
    return isSuperadmin || 
           roleName.contains('admin') || 
           roleName.contains('administrator');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      hasAccessDenied = false;
    });

    try {
      final userProfile = Provider.of<UserProfile>(context, listen: false);
      
      // Check if user has admin access
      if (!_hasAdminAccess(userProfile)) {
        setState(() {
          hasAccessDenied = true;
          errorMessage = 'Access Denied: You do not have permission to access this feature. Only Admin and Super Admin users can approve/reject user requests.';
        });
        return;
      }
      
      // Load utilities hierarchy
      final utilitiesResponse = await UtilityService.getUtilitiesHierarchy();
      if (utilitiesResponse != null) {
        utilities = utilitiesResponse.utilities;
      }

      // Load users data
      final usersResponse = await UserManagementService.getUsersData();
      if (usersResponse != null) {
        pendingUsers = usersResponse.pendingUsers;
      }

      // Check if current user has a utility assigned
      if (userProfile.utilityId > 0) {
        selectedUtilityId = userProfile.utilityId;
        isUtilityLocked = true;
      }

    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<UserData> get filteredPendingUsers {
    return UserManagementService.filterPendingUsersByUtility(
      pendingUsers, 
      selectedUtilityId
    );
  }

  String _getUtilityName(int utilityId) {
    final utility = utilities.firstWhere(
      (u) => u.utilityId == utilityId,
      orElse: () => UtilityData(utilityId: 0, utilityName: 'Unknown', substations: []),
    );
    return utility.utilityName;
  }

  void _showConfirmBox(UserData user, bool isApprove) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isApprove ? "Approve User?" : "Reject User?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isApprove
                ? "Are you sure you want to approve this user?"
                : "Are you sure you want to reject this user?"),
            SizedBox(height: 12),
            Text("Name: ${user.fullName}", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Email: ${user.email}"),
            Text("Designation: ${user.designation}"),
            Text("Utility: ${_getUtilityName(user.utilityId)}"),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Confirm"),
            style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _processUserAction(user, isApprove);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processUserAction(UserData user, bool isApprove) async {
    setState(() {
      isLoading = true;
    });

    try {
      bool success;
      if (isApprove) {
        success = await UserManagementService.approveUser(user.id);
      } else {
        success = await UserManagementService.rejectUser(user.id);
      }

      if (success) {
        setState(() {
          pendingUsers.removeWhere((u) => u.id == user.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${user.fullName} ${isApprove ? "approved" : "rejected"} successfully!",
            ),
            backgroundColor: isApprove ? Colors.green : Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to ${isApprove ? "approve" : "reject"} ${user.fullName}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve / Reject Users'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasAccessDenied
              ? _buildAccessDeniedScreen()
              : errorMessage != null
                  ? _buildErrorScreen()
                  : _buildMainContent(),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 24),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You do not have permission to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Only Admin and Super Admin users can approve or reject user requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you believe you should have access to this feature, please contact your system administrator.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            errorMessage!,
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Utility Dropdown
        Container(
          padding: EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Utility:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedUtilityId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Utility',
                      enabled: !isUtilityLocked,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Utilities'),
                      ),
                      ...utilities.map((utility) {
                        return DropdownMenuItem<int?>(
                          value: utility.utilityId,
                          child: Text(utility.utilityName),
                        );
                      }).toList(),
                    ],
                    onChanged: isUtilityLocked
                        ? null
                        : (value) {
                            setState(() {
                              selectedUtilityId = value;
                            });
                          },
                  ),
                  if (isUtilityLocked)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '🔒 Utility is locked to your assigned utility',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Pending Users List
        Expanded(
          child: filteredPendingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pending users found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        selectedUtilityId != null
                            ? 'Try selecting a different utility'
                            : 'All users have been processed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredPendingUsers.length,
                  itemBuilder: (context, idx) {
                    final user = filteredPendingUsers[idx];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.designation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'PENDING',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user.phone,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.business_outlined, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getUtilityName(user.utilityId),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.check, color: Colors.white),
                                    label: Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showConfirmBox(user, true),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.close, color: Colors.white),
                                    label: Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showConfirmBox(user, false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
