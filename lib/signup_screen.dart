import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_provider.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final designationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE); // Kesko blue
    final accentColor = Colors.white;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 8,
            shadowColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildFormField(
                      controller: usernameController,
                      label: 'Username',
                      icon: Icons.person,
                      color: primaryColor,
                      validator: (val) => val!.isEmpty ? 'Enter username' : null,
                    ),
                    SizedBox(height: 16),
                    _buildFormField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      color: primaryColor,
                      validator: (val) =>
                          val!.isEmpty || !val.contains('@') ? 'Enter valid email' : null,
                    ),
                    SizedBox(height: 16),
                    _buildFormField(
                      controller: mobileController,
                      label: 'Mobile Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      color: primaryColor,
                      validator: (val) =>
                          val!.isEmpty || val.length < 10 ? 'Enter valid mobile number' : null,
                    ),
                    SizedBox(height: 16),
                    _buildFormField(
                      controller: designationController,
                      label: 'Designation',
                      icon: Icons.work,
                      color: primaryColor,
                      validator: (val) => val!.isEmpty ? 'Enter designation' : null,
                    ),
                    SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: primaryColor,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Provider.of<UserProfile>(context, listen: false).updateProfile(
                              username: usernameController.text,
                              email: emailController.text,
                              mobile: mobileController.text,
                              designation: designationController.text,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => DashboardScreen()),
                            );
                          }
                        },
                        child: Text(
                          'Signup',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        labelText: label,
        labelStyle: TextStyle(color: color),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color), borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
