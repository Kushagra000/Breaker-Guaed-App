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
  DateTime? _startTime;
  DateTime? _endTime;
  
  // Duration inputs
  final TextEditingController _durationHoursController = TextEditingController(text: '2');
  final TextEditingController _durationMinutesController = TextEditingController(text: '0');
  
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
    _durationHoursController.addListener(_calculateEndTime);
    _durationMinutesController.addListener(_calculateEndTime);
    // Don't set start time here - it will be set when feeder is selected
  }

  @override
  void dispose() {
    _searchController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
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
    }
  }
  
  void _onFeederChanged(int? feederId) {
    setState(() {
      _selectedFeederId = feederId;
      _availableLinemen = [];
      _filteredLinemen = [];
      // Set start time to current time when feeder is selected
      if (feederId != null) {
        _startTime = DateTime.now();
        _calculateEndTime();
      } else {
        _startTime = null;
        _endTime = null;
      }
    });
    
    // Auto-load available linemen when feeder is selected
    if (feederId != null && _selectedSubstationId != null) {
      _loadAvailableLinemen();
    }
  }
  
  /// Calculate end time based on start time and duration
  void _calculateEndTime() {
    if (_startTime == null) return;
    
    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    
    final duration = Duration(hours: hours, minutes: minutes);
    
    setState(() {
      _endTime = _startTime!.add(duration);
    });
    
    // Reload available linemen if we have all required data
    if (_startTime != null && _endTime != null && _selectedSubstationId != null && _selectedFeederId != null) {
      _loadAvailableLinemen();
    }
  }

  Future<void> _loadAvailableLinemen() async {
    if (_selectedSubstationId == null || _selectedFeederId == null || _startTime == null || _endTime == null) {
      print('Missing required data for loading linemen:');
      print('Substation ID: $_selectedSubstationId');
      print('Feeder ID: $_selectedFeederId');
      print('Start Time: $_startTime');
      print('End Time: $_endTime');
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
      
      print('Loading available linemen with:');
      print('Substation ID: $_selectedSubstationId');
      print('Start Time: $startTimeStr');
      print('End Time: $endTimeStr');
      
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
        print('Loaded ${response.linemen.length} available linemen');
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
  
  // ... existing code ...

  Future<void> _submitAssignment() async {
    final errors = LinemanService.validateAssignmentData(
      purpose: selectedPurpose,
      substationId: _selectedSubstationId,
      feederId: _selectedFeederId,
      selectedLinemenIds: _availableLinemen.where((l) => l.isSelected).map((l) => l.id).toList(),
      startTime: _startTime,
      endTime: _endTime,
    );
    
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
      print('Selected Linemen IDs: $selectedLinemenIds');
      print('Assigned By: ${SessionManager.email}');
      print('============================');
      
      final assignment = AssignmentRequest(
        purpose: selectedPurpose,
        substationId: _selectedSubstationId!,
        assignedBy: SessionManager.email, // Add the email of the logged-in user
        shutdowns: [
          ShutdownAssignment(
            feederId: _selectedFeederId!,
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
      _startTime = null; // Will be set when feeder is selected
      _endTime = null;
      _availableLinemen = [];
      _filteredLinemen = [];
      _searchController.clear();
      _durationHoursController.text = '2';
      _durationMinutesController.text = '0';
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



  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        // Start time display (current time, read-only)
        _buildStartTimeDisplay(),
        SizedBox(height: 16),
        // Duration inputs
        _buildDurationInputs(),
        SizedBox(height: 16),
        // End time display (read-only)
        _buildEndTimeDisplay(),
      ],
    );
  }

  Widget _buildStartTimeDisplay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: _startTime != null ? Colors.blue[50] : Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            _startTime != null ? Icons.access_time : Icons.access_time_outlined,
            color: _startTime != null ? Colors.blue[600] : Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Time (Auto-set when feeder selected)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _startTime != null ? Colors.blue[600] : Colors.grey[600],
                  ),
                ),
                Text(
                  _startTime != null
                      ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                      : 'Will be set to current time when feeder is selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: _startTime != null ? Colors.black : Colors.grey,
                    fontWeight: _startTime != null ? FontWeight.w500 : FontWeight.normal,
                    fontStyle: _startTime == null ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Icon(
            _startTime != null ? Icons.check_circle : Icons.info_outline,
            color: _startTime != null ? Colors.green[400] : Colors.blue[400],
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDurationInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationHoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hours',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: '2',
                ),
                onChanged: (value) {
                  // Validate input
                  final hours = int.tryParse(value);
                  if (hours != null && hours >= 0 && hours <= 24) {
                    _calculateEndTime();
                  }
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _durationMinutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  prefixIcon: Icon(Icons.timer),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: '0',
                ),
                onChanged: (value) {
                  // Validate input
                  final minutes = int.tryParse(value);
                  if (minutes != null && minutes >= 0 && minutes < 60) {
                    _calculateEndTime();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEndTimeDisplay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End Time (Calculated)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _endTime != null
                      ? '${_endTime!.day}/${_endTime!.month}/${_endTime!.year} ${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                      : 'Will be calculated from start time + duration',
                  style: TextStyle(
                    fontSize: 16,
                    color: _endTime != null ? Colors.black : Colors.grey,
                    fontStyle: _endTime != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
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
    if (_selectedSubstationId == null || _selectedFeederId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select substation and feeder\nto view available linemen',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_startTime == null || _endTime == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Setting up schedule...\nStart time will be set automatically',
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