import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'manage_work_screen.dart';
import 'add_device_screen.dart';
import 'approve_reject_screen.dart';
import 'profile_screen.dart';
import 'activity_logs_screen.dart';
import 'user_profile_provider.dart';
import 'services/session_manager.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen(); // Remove the isAdmin parameter

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
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE); // Kesko Blue
    final manageWorkColor = const Color.fromARGB(255, 255, 130, 130);
    final manageWorkTextColor = Colors.red.shade700;

    // Button builder for consistent design
    Widget bigButton({
      required String text,
      required String subtext,
      required IconData icon,
      required Color color,
      required Color textColor,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon, size: 32, color: textColor),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              SizedBox(height: 8),
              Text(subtext, style: TextStyle(fontSize: 14, color: textColor)),
            ],
          ),
          onPressed: onTap,
        ),
      );
    }

    return Scaffold(
      floatingActionButton: Consumer<UserProfile>(
        builder: (context, userProfile, child) {
          return FloatingActionButton.extended(
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            backgroundColor: Colors.red,
            onPressed: () async {
              await userProfile.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with gradient
              Container(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<UserProfile>(
                                builder: (context, userProfile, child) {
                                  return Text(
                                    'Welcome, ${userProfile.username.isNotEmpty ? userProfile.username : SessionManager.displayName}',
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              Text('Manage and monitor feeder network operation', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              SizedBox(height: 8),
                              Consumer<UserProfile>(
                                builder: (context, userProfile, child) {
                                  return Text(
                                    '${userProfile.utilityName.isNotEmpty ? userProfile.utilityName : SessionManager.utilityName}',
                                    style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Profile Icon Button
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: IconButton(
                            icon: Icon(Icons.person, color: Colors.white, size: 25),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProfileScreen()),
                              );
                            },
                            tooltip: 'View Profile',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Your Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 16),
              bigButton(
                text: 'Manage Work',
                subtext: 'View and update feeder tasks',
                icon: Icons.settings_input_component,
                color: manageWorkColor,
                textColor: manageWorkTextColor,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ManageWorkScreen()));
                },
              ),
              // bigButton(
              //   text: 'My Profile',
              //   subtext: 'View account details and settings',
              //   icon: Icons.account_circle,
              //   color: Colors.blue.shade100,
              //   textColor: Colors.blue.shade700,
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
              //   },
              // ),
              // Admin-only buttons with role-based access control
              Consumer<UserProfile>(
                builder: (context, userProfile, child) {
                  if (!_hasAdminAccess(userProfile)) {
                    return SizedBox.shrink(); // Hide admin buttons for non-admin users
                  }
                  
                  return bigButton(
                    text: 'Add New Device',
                    subtext: 'Register new smart grid device',
                    icon: Icons.add_box,
                    color: Colors.green.shade100,
                    textColor: Colors.green.shade700,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddDeviceScreen()));
                    },
                  );
                },
              ),
              Consumer<UserProfile>(
                builder: (context, userProfile, child) {
                  if (!_hasAdminAccess(userProfile)) {
                    return SizedBox.shrink(); // Hide admin buttons for non-admin users
                  }
                  
                  return bigButton(
                    text: 'Approve / Reject',
                    subtext: 'Approve and reject users request',
                    icon: Icons.check_circle_outline,
                    color: Colors.indigo.shade100,
                    textColor: Colors.indigo.shade700,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ApproveRejectScreen()));
                    },
                  );
                },
              ),
              Consumer<UserProfile>(
                builder: (context, userProfile, child) {
                  if (!_hasAdminAccess(userProfile)) {
                    return SizedBox.shrink(); // Hide admin buttons for non-admin users
                  }
                  
                  return bigButton(
                    text: 'Activity Logs',
                    subtext: 'View system activity and audit logs',
                    icon: Icons.history,
                    color: Colors.purple.shade100,
                    textColor: Colors.purple.shade700,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityLogsScreen()));
                    },
                  );
                },
              ),
              // Bottom padding to account for FAB and provide breathing room
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}