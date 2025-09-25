import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'models/utility_hierarchy_model.dart';
import 'models/management_data_model.dart';
import 'services/utility_service.dart';
import 'services/management_service.dart';
import 'services/signup_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Dropdown values
  DesignationData? selectedDesignation;
  RoleData? selectedRole;
  UtilityData? selectedUtility;
  SubstationData? selectedSubstation;
  DepartmentData? selectedDepartment;

  // Data lists
  List<DesignationData> designations = [];
  List<RoleData> roles = [];
  List<DepartmentData> departments = [];
  List<UtilityData> utilities = [];
  List<SubstationData> substations = [];

  bool isLoading = true;
  bool isSubmitting = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      // Load utilities and management data in parallel (without authentication)
      final results = await Future.wait([
        UtilityService.getUtilitiesHierarchy(requireAuth: false),
        ManagementService.getManagementData(requireAuth: false),
      ]);

      final utilitiesResponse = results[0] as UtilityHierarchyResponse?;
      final managementResponse = results[1] as ManagementDataResponse?;

      if (mounted) {
        setState(() {
          if (utilitiesResponse != null) {
            utilities = utilitiesResponse.utilities;
          }
          if (managementResponse != null && managementResponse.success) {
            designations = managementResponse.data.designations;
            roles = managementResponse.data.roles;
            departments = managementResponse.data.departments;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading form data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load form data. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _loadFormData();
              },
            ),
          ),
        );
      }
    }
  }

  void _onUtilityChanged(UtilityData? utility) {
    setState(() {
      selectedUtility = utility;
      selectedSubstation = null;
      substations = utility?.substations ?? [];
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE); // Kesko blue
    final accentColor = Colors.white;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 48 : 24,
              vertical: 16,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth > 600 ? 500 : double.infinity,
              ),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: isLoading
                        ? _buildLoadingWidget(primaryColor)
                        : _buildSignupForm(primaryColor, accentColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading Registration Form...',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch the required data',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(Color primaryColor, Color accentColor) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(primaryColor),
          SizedBox(height: 32),
          
          // Personal Information Section
          _buildSectionHeader('Personal Information', Icons.person_outline),
          SizedBox(height: 16),
          
          _buildFormField(
            controller: fullNameController,
            label: 'Full Name',
            icon: Icons.person,
            color: primaryColor,
            validator: (val) => val!.isEmpty ? 'Enter your full name' : null,
          ),
          SizedBox(height: 20),
          
          _buildFormField(
            controller: emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            color: primaryColor,
            validator: (val) {
              if (val!.isEmpty) return 'Enter your email address';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          
          _buildFormField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            color: primaryColor,
            validator: (val) {
              if (val!.isEmpty) return 'Enter your phone number';
              if (val.length < 10) return 'Phone number must be at least 10 digits';
              return null;
            },
          ),
          SizedBox(height: 24),
          
          // Professional Information Section
          _buildSectionHeader('Professional Information', Icons.work_outline),
          SizedBox(height: 16),
          
          _buildDropdownField<DesignationData>(
            value: selectedDesignation,
            items: designations,
            label: 'Designation',
            icon: Icons.badge_outlined,
            color: primaryColor,
            onChanged: (value) => setState(() => selectedDesignation = value),
            itemBuilder: (designation) => Text(designation.designationName),
            validator: (val) => val == null ? 'Select your designation' : null,
          ),
          SizedBox(height: 20),
          
          _buildDropdownField<RoleData>(
            value: selectedRole,
            items: roles,
            label: 'Role',
            icon: Icons.admin_panel_settings_outlined,
            color: primaryColor,
            onChanged: (value) => setState(() => selectedRole = value),
            itemBuilder: (role) => Text(role.roleName),
            validator: (val) => val == null ? 'Select your role' : null,
          ),
          SizedBox(height: 20),
          
          _buildDropdownField<DepartmentData>(
            value: selectedDepartment,
            items: departments,
            label: 'Department',
            icon: Icons.domain_outlined,
            color: primaryColor,
            onChanged: (value) => setState(() => selectedDepartment = value),
            itemBuilder: (department) => Text(department.departmentName),
            validator: (val) => val == null ? 'Select your department' : null,
          ),
          SizedBox(height: 24),
          
          // Organization Information Section
          _buildSectionHeader('Organization Information', Icons.business_outlined),
          SizedBox(height: 16),
          
          // Utility Dropdown - Fixed responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDropdownField<UtilityData>(
                value: selectedUtility,
                items: utilities,
                label: 'Utility Company',
                icon: Icons.business,
                color: primaryColor,
                onChanged: _onUtilityChanged,
                itemBuilder: (utility) => Text(
                  utility.utilityName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                validator: (val) => val == null ? 'Select your utility company' : null,
                maxWidth: constraints.maxWidth,
              );
            },
          ),
          SizedBox(height: 20),
          
          // Substation Dropdown - Fixed responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDropdownField<SubstationData>(
                value: selectedSubstation,
                items: substations,
                label: 'Substation',
                icon: Icons.electrical_services_outlined,
                color: primaryColor,
                onChanged: (value) => setState(() => selectedSubstation = value),
                itemBuilder: (substation) => Text(
                  '${substation.substationName} (${substation.substationNumber})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                validator: (val) => val == null ? 'Select your substation' : null,
                enabled: selectedUtility != null,
                maxWidth: constraints.maxWidth,
              );
            },
          ),
          SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader('Security Information', Icons.security_outlined),
          SizedBox(height: 16),
          
          _buildPasswordField(
            controller: passwordController,
            label: 'Password',
            color: primaryColor,
            obscureText: obscurePassword,
            onToggleVisibility: () => setState(() => obscurePassword = !obscurePassword),
            validator: (val) {
              if (val!.length < 6) return 'Password must be at least 6 characters';
              if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(val)) {
                return 'Password must contain both letters and numbers';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          
          _buildPasswordField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            color: primaryColor,
            obscureText: obscureConfirmPassword,
            onToggleVisibility: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
            validator: (val) {
              if (val != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 32),
          
          // Submit Button
          _buildSubmitButton(primaryColor, accentColor),
          SizedBox(height: 16),
          
          // Login Link
          _buildLoginLink(primaryColor),
        ],
      ),
    );
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });

      try {
        final response = await SignupService.registerUser(
          fullName: fullNameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          designationId: selectedDesignation!.designationId,
          password: passwordController.text,
          roleId: selectedRole!.roleId,
          departmentId: selectedDepartment!.departmentId,
          utilityId: selectedUtility?.utilityId,
          substationId: selectedSubstation?.substationId,
        );

        if (mounted) {
          setState(() {
            isSubmitting = false;
          });

          if (response.success) {
            // Show success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                title: Text(
                  'Registration Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072CE),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      response.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Your account is pending approval. You will be notified once it\'s activated.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0072CE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      child: Text(
                        'Go to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                title: Text(
                  'Registration Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                content: Text(
                  response.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0072CE),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required List<T> items,
    required String label,
    required IconData icon,
    required Color color,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
    String? Function(T?)? validator,
    bool enabled = true,
    double? maxWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: enabled ? color : Colors.grey, size: 20),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? color : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: enabled ? color : Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: enabled
            ? items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: (maxWidth ?? 300) - 120, // Account for padding and icons
                    ),
                    child: itemBuilder(item),
                  ),
                );
              }).toList()
            : [],
        onChanged: enabled ? onChanged : null,
        validator: validator,
        hint: Container(
          constraints: BoxConstraints(
            maxWidth: (maxWidth ?? 300) - 120,
          ),
          child: Text(
            enabled ? 'Select $label' : 'Select utility first',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: enabled ? color : Colors.grey,
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
        isExpanded: true, // This helps prevent overflow
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required Color color,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_outline, color: color, size: 20),
          ),
          suffixIcon: Container(
            margin: EdgeInsets.all(12),
            child: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: color,
                size: 20,
              ),
              onPressed: onToggleVisibility,
              splashRadius: 20,
            ),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.person_add_alt_1,
            size: 48,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Join our platform and start managing your electrical infrastructure',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Color(0xFF0072CE),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0072CE),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 12),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0072CE).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Color primaryColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isSubmitting ? null : _handleSignup,
        child: isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Account...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: accentColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
