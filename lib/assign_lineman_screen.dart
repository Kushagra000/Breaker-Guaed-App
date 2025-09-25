import 'package:flutter/material.dart';
import 'services/utility_service.dart';
import 'services/lineman_service.dart';
import 'services/session_manager.dart';
import 'models/utility_hierarchy_model.dart';
import 'models/assignment_models.dart';

class AssignLinemanScreen extends StatefulWidget {
  @override
  _AssignLinemanScreenState createState() => _AssignLinemanScreenState();
}

class _AssignLinemanScreenState extends State<AssignLinemanScreen> {
  // Purpose options
  final List<String> purposeOptions = ['Maintenance', 'Fault', 'Shutdown'];
  String selectedPurpose = 'Maintenance';
  
  // Utility hierarchy data
  List<UtilityData> _availableUtilities = [];
  List<SubstationData> _availableSubstations = [];
  List<FeederData> _availableFeeders = [];
  
  // Selected values
  int? _selectedUtilityId;
  String? _selectedUtilityName;
  int? _selectedSubstationId;
  String? _selectedSubstationName;
  int? _selectedFeederId;
  
  // Assignment details
  int? _selectedSsoId;
  int? _selectedJeId;
  String? _selectedSsoName;  // Added to store SSO name
  String? _selectedJeName;   // Added to store JE name
  DateTime? _startTime;
  DateTime? _endTime;
  
  // SSO and JE data
  List<SubstationUser> _availableSsos = [];
  List<SubstationUser> _availableJes = [];
  bool _isUsersLoading = false;
  
  // Available linemen
  List<AvailableLineman> _availableLinemen = [];
  List<AvailableLineman> _filteredLinemen = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Loading states
  bool _isDataLoading = true;
  bool _isLinemenLoading = false;
  bool _isSubmitting = false;
  
  // Dropdown enabled states
  bool _isUtilityDropdownEnabled = true;
  bool _isSubstationDropdownEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterLinemen);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeData() async {
    try {
      await SessionManager.initialize();
      
      print('=== INITIALIZATION DEBUG ===');
      print('User logged in: ${SessionManager.isLoggedIn}');
      print('User utility ID: ${SessionManager.utilityId}');
      print('User substation ID: ${SessionManager.substationId}');
      print('============================');
      
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
        setState(() {
          _availableUtilities = hierarchyData.utilities;
        });
        
        final userUtilityId = SessionManager.utilityId;
        if (userUtilityId > 0) {
          print('=== USER HAS PREDEFINED UTILITY ===');
          print('User Utility ID: $userUtilityId');
          _selectedUtilityId = userUtilityId;
          _isUtilityDropdownEnabled = false;
          await _loadUtilityName(userUtilityId);
          await _loadSubstationsForUtility(userUtilityId);
          
          final userSubstationId = SessionManager.substationId;
          if (userSubstationId > 0) {
            print('=== USER HAS PREDEFINED SUBSTATION ===');
            print('User Substation ID: $userSubstationId');
            _selectedSubstationId = userSubstationId;
            _isSubstationDropdownEnabled = false;
            await _loadSubstationName(userSubstationId);
            await _loadFeedersForSubstation(userSubstationId);
            
            print('About to load substation users for predefined substation...');
            await _loadSubstationUsers(userSubstationId);  // Load SSO and JE users for predefined substation
            print('Finished loading substation users for predefined substation');
          }
        } else {
          print('User has no predefined utility - enabling utility dropdown');
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
    final utility = UtilityService.getUtilityById(_availableUtilities, utilityId);
    if (utility != null) {
      setState(() {
        _selectedUtilityName = utility.utilityName;
      });
    }
  }
  
  Future<void> _loadSubstationName(int substationId) async {
    try {
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
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
    setState(() {
      _availableSubstations = UtilityService.getSubstationsByUtilityId(_availableUtilities, utilityId);
    });
  }
  
  Future<void> _loadFeedersForSubstation(int substationId) async {
    final substation = _availableSubstations.firstWhere(
      (s) => s.substationId == substationId,
      orElse: () => SubstationData(
        substationId: 0,
        substationName: 'Unknown',
        substationNumber: 'Unknown',
        feeders: [],
      ),
    );
    
    setState(() {
      _availableFeeders = substation.feeders;
    });
  }

  Future<void> _loadSubstationUsers(int substationId) async {
    print('=== LOADING SUBSTATION USERS ===');
    print('Substation ID: $substationId');
    
    setState(() {
      _isUsersLoading = true;
      _availableSsos = [];
      _availableJes = [];
      _selectedSsoId = null;
      _selectedJeId = null;
      _selectedSsoName = null;  // Reset SSO name
      _selectedJeName = null;   // Reset JE name
    });
    
    try {
      print('Calling LinemanService.getSubstationUsers...');
      final response = await LinemanService.getSubstationUsers(substationId);
      
      print('API Response: $response');
      
      if (response['success']) {
        print('Response successful, parsing data...');
        final usersData = SubstationUsersResponse.fromJson(response['data']);
        print('SSO count: ${usersData.sso.length}');
        print('JE count: ${usersData.je.length}');
        
        if (usersData.sso.isNotEmpty) {
          print('SSO users:');
          usersData.sso.forEach((sso) => print('  - ${sso.name} (ID: ${sso.id})'));
        }
        
        if (usersData.je.isNotEmpty) {
          print('JE users:');
          usersData.je.forEach((je) => print('  - ${je.name} (ID: ${je.id})'));
        }
        
        setState(() {
          _availableSsos = usersData.sso;
          _availableJes = usersData.je;
        });
        
        print('State updated with ${_availableSsos.length} SSOs and ${_availableJes.length} JEs');
      } else {
        print('API returned error: ${response['message']}');
        _showErrorMessage(response['message'] ?? 'Failed to load substation users');
      }
    } catch (e) {
      print('Exception in _loadSubstationUsers: $e');
      _showErrorMessage('Error loading substation users: $e');
    } finally {
      setState(() {
        _isUsersLoading = false;
      });
      print('=== SUBSTATION USERS LOADING COMPLETE ===');
    }
  }

  void _onUtilityChanged(int? utilityId) {
    setState(() {
      _selectedUtilityId = utilityId;
      _selectedSubstationId = null;
      _selectedFeederId = null;
      _availableSubstations = [];
      _availableFeeders = [];
      _availableLinemen = [];
      _filteredLinemen = [];
    });
    
    if (utilityId != null) {
      _loadSubstationsForUtility(utilityId);
    }
  }
  
  void _onSubstationChanged(int? substationId) {
    setState(() {
      _selectedSubstationId = substationId;
      _selectedFeederId = null;
      _availableFeeders = [];
      _availableLinemen = [];
      _filteredLinemen = [];
    });
    
    if (substationId != null) {
      _loadFeedersForSubstation(substationId);
      _loadSubstationUsers(substationId); // Load SSO and JE users when substation changes
    }
  }
  
  void _onFeederChanged(int? feederId) {
    setState(() {
      _selectedFeederId = feederId;
      _availableLinemen = [];
      _filteredLinemen = [];
    });
  }

  Future<void> _loadAvailableLinemen() async {
    if (_selectedSubstationId == null || _startTime == null || _endTime == null) {
      _showErrorMessage('Please select substation, start time, and end time first');
      return;
    }
    
    setState(() {
      _isLinemenLoading = true;
      _availableLinemen = [];
      _filteredLinemen = [];
    });
    
    try {
      final startTimeStr = _startTime!.toIso8601String().substring(0, 19);
      final endTimeStr = _endTime!.toIso8601String().substring(0, 19);
      
      final response = await LinemanService.getAvailableLinemen(
        substationId: _selectedSubstationId!,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );
      
      if (response.success) {
        setState(() {
          _availableLinemen = response.linemen;
          _filteredLinemen = List.from(response.linemen);
        });
      } else {
        _showErrorMessage(response.message);
      }
    } catch (e) {
      _showErrorMessage('Error loading available linemen: $e');
    } finally {
      setState(() {
        _isLinemenLoading = false;
      });
    }
  }
  
  void _filterLinemen() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLinemen = _availableLinemen.where((lineman) =>
          lineman.name.toLowerCase().contains(query) ||
          lineman.phone.contains(query) ||
          lineman.email.toLowerCase().contains(query)
      ).toList();
    });
  }
  
  Future<void> _selectDateTime({required bool isStartTime}) async {
    final DateTime now = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime 
          ? (_startTime ?? now.add(Duration(hours: 1)))
          : (_endTime ?? now.add(Duration(hours: 2))),
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );
    
    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime 
              ? (_startTime ?? now.add(Duration(hours: 1)))
              : (_endTime ?? now.add(Duration(hours: 2)))
        ),
      );
      
      if (selectedTime != null) {
        final DateTime fullDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        setState(() {
          if (isStartTime) {
            _startTime = fullDateTime;
            if (_endTime == null || _endTime!.isBefore(fullDateTime.add(Duration(hours: 1)))) {
              _endTime = fullDateTime.add(Duration(hours: 2));
            }
          } else {
            _endTime = fullDateTime;
          }
        });
        
        if (_startTime != null && _endTime != null) {
          _loadAvailableLinemen();
        }
      }
    }
  }

  Future<void> _submitAssignment() async {
    final errors = LinemanService.validateAssignmentData(
      purpose: selectedPurpose,
      substationId: _selectedSubstationId,
      feederId: _selectedFeederId,
      ssoId: _selectedSsoId,
      jeId: _selectedJeId,
      selectedLinemenIds: _availableLinemen.where((l) => l.isSelected).map((l) => l.id).toList(),
      startTime: _startTime,
      endTime: _endTime,
    );
    
    // Additional validation for SSO and JE names
    if (_selectedSsoName == null || _selectedSsoName!.trim().isEmpty) {
      errors['sso'] = 'SSO name is missing - please reselect SSO';
    }
    
    if (_selectedJeName == null || _selectedJeName!.trim().isEmpty) {
      errors['je'] = 'JE name is missing - please reselect JE';
    }
    
    if (errors.isNotEmpty) {
      _showErrorMessage(errors.values.first!);
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final startTimeStr = _startTime!.toIso8601String().substring(0, 19);
      final endTimeStr = _endTime!.toIso8601String().substring(0, 19);
      
      final selectedLinemenIds = _availableLinemen
          .where((l) => l.isSelected)
          .map((l) => l.id)
          .toList();
      
      print('=== ASSIGNMENT DEBUG INFO ===');
      print('Selected SSO ID: $_selectedSsoId, Name: $_selectedSsoName');
      print('Selected JE ID: $_selectedJeId, Name: $_selectedJeName');
      print('Selected Linemen IDs: $selectedLinemenIds');
      print('============================');
      
      final assignment = AssignmentRequest(
        purpose: selectedPurpose,
        substationId: _selectedSubstationId!,
        shutdowns: [
          ShutdownAssignment(
            feederId: _selectedFeederId!,
            ssoId: _selectedSsoId!,
            jeId: _selectedJeId!,
            ssoName: _selectedSsoName!,
            jeName: _selectedJeName!,
            linemenIds: selectedLinemenIds,
            startTime: startTimeStr,
            endTime: endTimeStr,
          ),
        ],
      );
      
      final response = await LinemanService.submitAssignment(assignment);
      
      if (response['success']) {
        _showSuccessMessage(response['message'] ?? 'Assignment submitted successfully');
        _resetForm();
      } else {
        _showErrorMessage(response['message'] ?? 'Failed to submit assignment');
      }
    } catch (e) {
      _showErrorMessage('Error submitting assignment: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  void _resetForm() {
    setState(() {
      selectedPurpose = 'Maintenance';
      _selectedFeederId = null;
      _selectedSsoId = null;
      _selectedJeId = null;
      _selectedSsoName = null;  // Reset SSO name
      _selectedJeName = null;   // Reset JE name
      _startTime = null;
      _endTime = null;
      _availableLinemen = [];
      _filteredLinemen = [];
      _searchController.clear();
    });
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
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  bool get _canSubmit {
    return selectedPurpose.isNotEmpty &&
        _selectedSubstationId != null &&
        _selectedFeederId != null &&
        _selectedSsoId != null &&
        _selectedJeId != null &&
        _selectedSsoName != null &&  // Added SSO name check
        _selectedJeName != null &&   // Added JE name check
        _startTime != null &&
        _endTime != null &&
        _availableLinemen.any((l) => l.isSelected) &&
        !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Lineman', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Schedule shutdown and assign linemen', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        backgroundColor: Color(0xFF0072CE),
        toolbarHeight: 80,
      ),
      body: _isDataLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPurposeDropdown(),
                  SizedBox(height: 16),
                  _buildUtilityDropdown(),
                  SizedBox(height: 16),
                  _buildSubstationDropdown(),
                  SizedBox(height: 16),
                  _buildFeederDropdown(),
                  SizedBox(height: 20),
                  _buildAssignmentDetailsSection(),
                  SizedBox(height: 20),
                  _buildDateTimeSection(),
                  SizedBox(height: 20),
                  _buildLinemenSection(),
                  SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildPurposeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Purpose',
        prefixIcon: Icon(Icons.work),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: selectedPurpose,
      items: purposeOptions.map((purpose) => DropdownMenuItem(value: purpose, child: Text(purpose))).toList(),
      onChanged: (val) => setState(() => selectedPurpose = val ?? 'Maintenance'),
    );
  }
  
  Widget _buildUtilityDropdown() {
    if (!_isUtilityDropdownEnabled) {
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
      items: _availableUtilities.map((utility) => DropdownMenuItem<int>(
        value: utility.utilityId,
        child: Text(
          utility.utilityName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: _onUtilityChanged,
      isExpanded: true, // Prevents overflow
    );
  }
  
  Widget _buildSubstationDropdown() {
    if (!_isSubstationDropdownEnabled) {
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
      hint: Text(_selectedUtilityId == null ? 'First select a utility company' : 'Choose a substation'),
      items: _availableSubstations.map((substation) => DropdownMenuItem<int>(
        value: substation.substationId,
        child: Text(
          '${substation.substationName} (${substation.substationNumber})',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: _selectedUtilityId == null ? null : _onSubstationChanged,
      isExpanded: true, // Prevents overflow
    );
  }
  
  Widget _buildFeederDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedFeederId,
      decoration: InputDecoration(
        labelText: 'Select Feeder',
        prefixIcon: Icon(Icons.power),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text(_selectedSubstationId == null ? 'First select a substation' : 'Choose a feeder'),
      items: _availableFeeders.map((feeder) => DropdownMenuItem<int>(
        value: feeder.feederId,
        child: Text(
          '${feeder.feederName} (${feeder.feederNumber})',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: _selectedSubstationId == null ? null : _onFeederChanged,
      isExpanded: true, // Prevents overflow
    );
  }

  Widget _buildAssignmentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assignment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        // Use Column layout on smaller screens, Row on larger screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Stack vertically on smaller screens
              return Column(
                children: [
                  _buildSsoDropdown(),
                  SizedBox(height: 16),
                  _buildJeDropdown(),
                ],
              );
            } else {
              // Side by side on larger screens
              return Row(
                children: [
                  Expanded(child: _buildSsoDropdown()),
                  SizedBox(width: 16),
                  Expanded(child: _buildJeDropdown()),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSsoDropdown() {
    return _isUsersLoading
        ? Container(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          )
        : DropdownButtonFormField<int>(
            value: _selectedSsoId,
            decoration: InputDecoration(
              labelText: 'Select SSO',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            hint: Text(_selectedSubstationId == null ? 'First select substation' : 'Choose SSO'),
            items: _availableSsos.map((sso) => DropdownMenuItem<int>(
              value: sso.id,
              child: Text(
                sso.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )).toList(),
            onChanged: _selectedSubstationId == null ? null : (val) {
              setState(() {
                _selectedSsoId = val;
                // Find the SSO name for the selected ID
                final selectedSso = _availableSsos.firstWhere(
                  (sso) => sso.id == val,
                  orElse: () => SubstationUser(id: 0, name: ''),
                );
                _selectedSsoName = selectedSso.name;
              });
            },
            isExpanded: true, // Prevents overflow
          );
  }

  Widget _buildJeDropdown() {
    return _isUsersLoading
        ? Container(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          )
        : DropdownButtonFormField<int>(
            value: _selectedJeId,
            decoration: InputDecoration(
              labelText: 'Select JE',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            hint: Text(_selectedSubstationId == null ? 'First select substation' : 'Choose JE'),
            items: _availableJes.map((je) => DropdownMenuItem<int>(
              value: je.id,
              child: Text(
                je.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )).toList(),
            onChanged: _selectedSubstationId == null ? null : (val) {
              setState(() {
                _selectedJeId = val;
                // Find the JE name for the selected ID
                final selectedJe = _availableJes.firstWhere(
                  (je) => je.id == val,
                  orElse: () => SubstationUser(id: 0, name: ''),
                );
                _selectedJeName = selectedJe.name;
              });
            },
            isExpanded: true, // Prevents overflow
          );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        // Use Column layout on smaller screens, Row on larger screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Stack vertically on smaller screens
              return Column(
                children: [
                  _buildTimeSelector(isStartTime: true),
                  SizedBox(height: 16),
                  _buildTimeSelector(isStartTime: false),
                ],
              );
            } else {
              // Side by side on larger screens
              return Row(
                children: [
                  Expanded(child: _buildTimeSelector(isStartTime: true)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTimeSelector(isStartTime: false)),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelector({required bool isStartTime}) {
    final selectedTime = isStartTime ? _startTime : _endTime;
    final label = isStartTime ? 'Start Time' : 'End Time';
    final placeholder = isStartTime ? 'Select start time' : 'Select end time';
    
    return InkWell(
      onTap: () => _selectDateTime(isStartTime: isStartTime),
      child: Container(
        width: double.infinity, // Full width
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600]),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    selectedTime != null
                        ? '${selectedTime.day}/${selectedTime.month}/${selectedTime.year} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'
                        : placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedTime != null ? Colors.black : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinemenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available Linemen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_availableLinemen.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var lineman in _availableLinemen) {
                      lineman.isSelected = !_availableLinemen.every((l) => l.isSelected);
                    }
                  });
                },
                child: Text(_availableLinemen.every((l) => l.isSelected) ? 'Deselect All' : 'Select All'),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (_availableLinemen.isNotEmpty) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search Lineman',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
        ],
        Container(
          height: 300,
          child: _buildLinemenList(),
        ),
      ],
    );
  }
  
  Widget _buildLinemenList() {
    if (_selectedSubstationId == null || _startTime == null || _endTime == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select substation and schedule time\nto view available linemen',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_isLinemenLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_filteredLinemen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No available linemen found\nfor the selected time slot',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAvailableLinemen,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0072CE)),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredLinemen.length,
      itemBuilder: (context, index) {
        final lineman = _filteredLinemen[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            title: Text(lineman.name, style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lineman.phone.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(lineman.phone, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                if (lineman.email.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(lineman.email, style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
              ],
            ),
            value: lineman.isSelected,
            onChanged: (val) => setState(() => lineman.isSelected = val ?? false),
            secondary: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[700]),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSubmitButton() {
    final selectedCount = _availableLinemen.where((l) => l.isSelected).length;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canSubmit ? _submitAssignment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0072CE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...', style: TextStyle(fontSize: 16)),
                ],
              )
            : Text(
                selectedCount > 0
                    ? 'Assign $selectedCount Lineman${selectedCount > 1 ? 's' : ''}'
                    : 'Assign Linemen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}