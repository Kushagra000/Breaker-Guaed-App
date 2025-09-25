import 'package:flutter/material.dart';
import 'services/lineman_service.dart';
import 'services/utility_service.dart';
import 'services/session_manager.dart';
import 'models/utility_hierarchy_model.dart';

class LinemanScreen extends StatefulWidget {
  @override
  _LinemanScreenState createState() => _LinemanScreenState();
}

class _LinemanScreenState extends State<LinemanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedStatus = 'Active';
  int? _selectedUtilityId;
  String? _selectedUtilityName;
  int? _selectedSubstationId;
  String? _selectedSubstationName;
  
  List<UtilityData> _availableUtilities = [];
  List<SubstationData> _availableSubstations = [];
  bool _isUtilityDropdownEnabled = true;
  bool _isSubstationDropdownEnabled = true;
  bool _isLoading = false;
  bool _isDataLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    try {
      await SessionManager.initialize();
      
      // Load utilities hierarchy first
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
        setState(() {
          _availableUtilities = hierarchyData.utilities;
        });
        
        // Check if user has a predefined utility ID
        final userUtilityId = SessionManager.utilityId;
        
        if (userUtilityId > 0) {
          // User has a predefined utility - lock it and load its name
          _selectedUtilityId = userUtilityId;
          _isUtilityDropdownEnabled = false;
          await _loadUtilityName(userUtilityId);
          
          // Load substations for this utility
          await _loadSubstationsForUtility(userUtilityId);
          
          // Check if user also has a predefined substation ID
          final userSubstationId = SessionManager.substationId;
          if (userSubstationId > 0) {
            // User has a predefined substation - lock it too
            _selectedSubstationId = userSubstationId;
            _isSubstationDropdownEnabled = false;
            await _loadSubstationName(userSubstationId);
          }
        } else {
          // User doesn't have predefined utility - enable utility dropdown
          _isUtilityDropdownEnabled = true;
        }
      }
    } catch (e) {
      _showErrorMessage('Error loading data: $e');
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }
  
  Future<void> _loadUtilityName(int utilityId) async {
    try {
      final utility = UtilityService.getUtilityById(_availableUtilities, utilityId);
      if (utility != null) {
        setState(() {
          _selectedUtilityName = utility.utilityName;
        });
      }
    } catch (e) {
      print('Error loading utility name: $e');
    }
  }
  
  Future<void> _loadSubstationName(int substationId) async {
    try {
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
        final userUtilityId = SessionManager.utilityId;
        
        // First, try to find the substation within user's utility
        if (userUtilityId > 0) {
          final userUtility = UtilityService.getUtilityById(hierarchyData.utilities, userUtilityId);
          if (userUtility != null) {
            final substation = UtilityService.getSubstationById(userUtility, substationId);
            if (substation != null) {
              setState(() {
                _selectedSubstationName = substation.substationName;
              });
              return;
            }
          }
        }
        
        // Fallback: search in all utilities if not found in user's utility
        for (var utility in hierarchyData.utilities) {
          for (var substation in utility.substations) {
            if (substation.substationId == substationId) {
              setState(() {
                _selectedSubstationName = substation.substationName;
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading substation name: $e');
    }
  }
  
  Future<void> _loadSubstationsForUtility(int utilityId) async {
    try {
      setState(() {
        _availableSubstations = UtilityService.getSubstationsByUtilityId(_availableUtilities, utilityId);
      });
    } catch (e) {
      _showErrorMessage('Error loading substations: $e');
    }
  }
  
  Future<void> _loadAvailableSubstations() async {
    try {
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
        List<SubstationData> filteredSubstations = [];
        
        // Check if user has a specific utility_id
        final userUtilityId = SessionManager.utilityId;
        
        if (userUtilityId > 0) {
          // Filter substations to only show those from user's utility
          filteredSubstations = UtilityService.getSubstationsByUtilityId(
            hierarchyData.utilities, 
            userUtilityId
          );
        } else {
          // If no utility_id, show all substations (fallback)
          filteredSubstations = UtilityService.getAllSubstations(hierarchyData.utilities);
        }
        
        setState(() {
          _availableSubstations = filteredSubstations;
        });
      }
    } catch (e) {
      _showErrorMessage('Error loading substations: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveLineman() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedSubstationId == null) {
      _showErrorMessage('Please select a substation');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      
      final result = await LinemanService.addLineman(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        status: _selectedStatus.trim(),
        substationId: _selectedSubstationId!,
        utilityId: _selectedUtilityId,
      );

      if (result['success']) {
        _showSuccessMessage(result['message']);
        _clearForm();
      } else {
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      _showErrorMessage('Error saving lineman: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onUtilityChanged(int? utilityId) {
    setState(() {
      _selectedUtilityId = utilityId;
      _selectedSubstationId = null; // Reset substation selection
      _availableSubstations = [];
    });
    
    if (utilityId != null) {
      _loadSubstationsForUtility(utilityId);
    }
  }
  
  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    setState(() {
      _selectedStatus = 'Active';
      if (_isUtilityDropdownEnabled) {
        _selectedUtilityId = null;
        _availableSubstations = [];
      }
      if (_isSubstationDropdownEnabled) {
        _selectedSubstationId = null;
      }
    });
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Lineman', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Add a new lineman to the system', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        backgroundColor: primaryColor,
        toolbarHeight: 80,
      ),
      body: _isDataLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildUtilityDropdown(),
                    SizedBox(height: 20),
                    _buildSubstationDropdown(),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Lineman Name',
                      icon: Icons.person,
                      validatorMsg: 'Please enter lineman name',
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validatorMsg: 'Please enter phone number',
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validatorMsg: 'Please enter email address',
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _buildStatusDropdown(),
                    SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _saveLineman,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Lineman',
                                style: TextStyle(fontSize: 18,color: Color(0xFFFFFFFF ), fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String validatorMsg,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: customValidator ?? (val) => val == null || val.isEmpty ? validatorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.work),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: ['Active', 'Inactive'].map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Row(
            children: [
              Icon(
                status == 'Active' ? Icons.check_circle : Icons.cancel,
                color: status == 'Active' ? Colors.green : Colors.red,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(status),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStatus = newValue;
          });
        }
      },
      validator: (value) => value == null || value.isEmpty ? 'Please select status' : null,
    );
  }
  
  Widget _buildUtilityDropdown() {
    if (!_isUtilityDropdownEnabled) {
      // Show disabled dropdown with predefined utility
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Utility Company (Assigned)',
          prefixIcon: Icon(Icons.business),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: Icon(Icons.lock, color: Colors.grey),
        ),
        controller: TextEditingController(text: _selectedUtilityName ?? 'Loading...'),
      );
    }
    
    return DropdownButtonFormField<int>(
      value: _selectedUtilityId,
      decoration: InputDecoration(
        labelText: 'Select Utility Company',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text('Choose a utility company'),
      items: _availableUtilities.map((UtilityData utility) {
        return DropdownMenuItem<int>(
          value: utility.utilityId,
          child: Text(utility.utilityName),
        );
      }).toList(),
      onChanged: _onUtilityChanged,
      validator: (value) => value == null ? 'Please select a utility company' : null,
    );
  }
  
  Widget _buildSubstationDropdown() {
    if (!_isSubstationDropdownEnabled) {
      // Show disabled dropdown with predefined substation
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Substation (Assigned)',
          prefixIcon: Icon(Icons.electrical_services),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: Icon(Icons.lock, color: Colors.grey),
        ),
        controller: TextEditingController(text: _selectedSubstationName ?? 'Loading...'),
      );
    }
    
    return DropdownButtonFormField<int>(
      value: _selectedSubstationId,
      decoration: InputDecoration(
        labelText: 'Select Substation',
        prefixIcon: Icon(Icons.electrical_services),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text(_selectedUtilityId == null 
          ? 'First select a utility company' 
          : 'Choose a substation'),
      items: _availableSubstations.map((SubstationData substation) {
        return DropdownMenuItem<int>(
          value: substation.substationId,
          child: Text('${substation.substationName} (${substation.substationNumber})'),
        );
      }).toList(),
      onChanged: _selectedUtilityId == null ? null : (int? newValue) {
        setState(() {
          _selectedSubstationId = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a substation' : null,
    );
  }
}
