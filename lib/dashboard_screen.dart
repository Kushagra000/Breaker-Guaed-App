import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'manage_work_screen.dart';
import 'add_device_screen.dart';         // New page import
import 'approve_reject_screen.dart';     // New page import

class DashboardScreen extends StatelessWidget {
  final bool isAdmin;
  DashboardScreen({this.isAdmin = true}); // Pass true for admin users

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
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section with gradient
          Container(
            padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
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
                Text('Welcome, Junior Engineer', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Manage and monitor feeder network operation', style: TextStyle(color: Colors.white70, fontSize: 16)),
                SizedBox(height: 8),
                Text('KESKO Smart Grid', style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Your Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 32),
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

if (isAdmin) ...[
  bigButton(
    text: 'Add New Device',
    subtext: 'Register new smart grid device',
    icon: Icons.add_box,
    color: Colors.green.shade100,
    textColor: Colors.green.shade700,
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AddDeviceScreen()));
    },
  ),
  bigButton(
    text: 'Approve / Reject',
    subtext: 'Approve and reject users request',
    icon: Icons.check_circle_outline,
    color: Colors.indigo.shade100,
    textColor: Colors.indigo.shade700,
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ApproveRejectScreen()));
    },
  ),
],

          SizedBox(height: 80),
        ],
      ),
    );
  }
}
