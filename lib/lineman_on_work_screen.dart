import 'package:flutter/material.dart';
import 'services/lineman_service.dart';
import 'services/utility_service.dart';
import 'services/session_manager.dart';
import 'models/utility_hierarchy_model.dart';
import 'models/lineman_on_work_model.dart';
import 'user_profile_provider.dart';
import 'package:provider/provider.dart';

class LinemanOnWorkScreen extends StatefulWidget {
  @override
  _LinemanOnWorkScreenState createState() => _LinemanOnWorkScreenState();
}

class _LinemanOnWorkScreenState extends State<LinemanOnWorkScreen> {
  // Utility hierarchy data
  List<UtilityData> _availableUtilities = [];
  List<SubstationData> _availableSubstations = [];
  List<SubstationData> _filteredSubstations = [];
  
  // Selected values
  int? _selectedUtilityId;
  String? _selectedUtilityName;
  int? _selectedSubstationId;
  String? _selectedSubstationName;
  
  // Linemen on work data
  List<LinemanOnWork> _linemenOnWork = [];
  
  // UI state
  bool _isUtilityDropdownEnabled = true;
  bool _isSubstationDropdownEnabled = true;
  bool _isLoading = false;
  bool _isDataLoading = true;
  bool _isLinemenLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    setState(() {
      _isDataLoading = true;
    });
    
    try {
      await SessionManager.initialize();
      
      // Load utilities hierarchy first
      final hierarchyData = await UtilityService.getUtilitiesHierarchy();
      if (hierarchyData != null) {
        setState(() {
          _availableUtilities = hierarchyData.utilities;
        });
        
        // Check if user has specific utility/substation restrictions
        await _applyUserRestrictions();
      }
    } catch (e) {
      print('Error initializing data: $e');
      _showErrorSnackBar('Failed to load utilities data: $e');
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }
  
  Future<void> _applyUserRestrictions() async {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    
    // If user is not superadmin, restrict to their utility
    if (!userProfile.isSuperadmin && userProfile.utilityId > 0) {
      final userUtility = _availableUtilities.firstWhere(
        (utility) => utility.utilityId == userProfile.utilityId,
        orElse: () => _availableUtilities.first,
      );
      
      setState(() {
        _selectedUtilityId = userUtility.utilityId;
        _selectedUtilityName = userUtility.utilityName;
        _isUtilityDropdownEnabled = false; // Freeze utility dropdown
        _filteredSubstations = userUtility.substations;
        _availableSubstations = userUtility.substations;
      });
      
      // Check if user also has a specific substation assigned
      if (userProfile.substationId > 0) {
        final userSubstation = userUtility.substations.firstWhere(
          (substation) => substation.substationId == userProfile.substationId,
          orElse: () => userUtility.substations.isNotEmpty ? userUtility.substations.first : SubstationData(
            substationId: userProfile.substationId,
            substationName: 'User Substation',
            substationNumber: 'SS-${userProfile.substationId}',
            feeders: [],
          ),
        );
        
        setState(() {
          _selectedSubstationId = userSubstation.substationId;
          _selectedSubstationName = userSubstation.substationName;
          _isSubstationDropdownEnabled = false; // Freeze substation dropdown
        });
        
        print('User restricted to substation: ${userSubstation.substationName}');
        
        // Auto-load linemen for the user's substation
        _loadLinemenOnWork();
      }
      
      print('User restricted to utility: ${userUtility.utilityName}');
    } else {
      // Superadmin can see all utilities
      setState(() {
        _availableSubstations = UtilityService.getAllSubstations(_availableUtilities);
      });
      print('Superadmin: Can access all utilities');
    }
  }
  
  void _onUtilityChanged(int? utilityId) {
    if (utilityId == null || !_isUtilityDropdownEnabled) return;
    
    final selectedUtility = _availableUtilities.firstWhere(
      (utility) => utility.utilityId == utilityId,
    );
    
    setState(() {
      _selectedUtilityId = utilityId;
      _selectedUtilityName = selectedUtility.utilityName;
      _selectedSubstationId = null;
      _selectedSubstationName = null;
      _filteredSubstations = selectedUtility.substations;
      _linemenOnWork = []; // Clear linemen data when utility changes
    });
    
    print('Selected utility: ${selectedUtility.utilityName}');
  }
  
  void _onSubstationChanged(int? substationId) {
    if (substationId == null) return;
    
    final selectedSubstation = _filteredSubstations.firstWhere(
      (substation) => substation.substationId == substationId,
    );
    
    setState(() {
      _selectedSubstationId = substationId;
      _selectedSubstationName = selectedSubstation.substationName;
    });
    
    print('Selected substation: ${selectedSubstation.substationName}');
    
    // Load linemen on work for the selected substation
    _loadLinemenOnWork();
  }
  
  Future<void> _loadLinemenOnWork() async {
    if (_selectedSubstationId == null) return;
    
    setState(() {
      _isLinemenLoading = true;
    });
    
    try {
      final response = await LinemanService.getLinemenOnWork(_selectedSubstationId!);
      
      setState(() {
        _linemenOnWork = response.linemen;
      });
      
      if (!response.success) {
        _showErrorSnackBar('Failed to load linemen on work');
      }
    } catch (e) {
      print('Error loading linemen on work: $e');
      _showErrorSnackBar('Error loading linemen: $e');
    } finally {
      setState(() {
        _isLinemenLoading = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildUtilityDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: _isUtilityDropdownEnabled ? Colors.white : Colors.grey.shade100,
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedUtilityId,
        decoration: InputDecoration(
          labelText: 'Select Utility',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: _isUtilityDropdownEnabled 
              ? Icon(Icons.arrow_drop_down) 
              : Icon(Icons.lock, color: Colors.grey),
        ),
        isExpanded: true,
        items: _availableUtilities.map((utility) {
          return DropdownMenuItem<int>(
            value: utility.utilityId,
            child: Text(
              utility.utilityName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: _isUtilityDropdownEnabled ? _onUtilityChanged : null,
        validator: (value) => value == null ? 'Please select a utility' : null,
      ),
    );
  }
  
  Widget _buildSubstationDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: _isSubstationDropdownEnabled ? Colors.white : Colors.grey.shade100,
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedSubstationId,
        decoration: InputDecoration(
          labelText: 'Select Substation',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: _isSubstationDropdownEnabled 
              ? Icon(Icons.arrow_drop_down) 
              : Icon(Icons.lock, color: Colors.grey),
        ),
        isExpanded: true,
        items: _filteredSubstations.map((substation) {
          return DropdownMenuItem<int>(
            value: substation.substationId,
            child: Text(
              '${substation.substationName} (${substation.substationNumber})',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: _isSubstationDropdownEnabled ? _onSubstationChanged : null,
        validator: (value) => value == null ? 'Please select a substation' : null,
      ),
    );
  }
  
  Widget _buildLinemanCard(LinemanOnWork lineman) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.engineering, color: Colors.white),
        ),
        title: Text(
          lineman.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(lineman.phone),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lineman.email,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(lineman.purpose),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Start: ${_formatDateTime(lineman.startTime)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'End: ${_formatDateTime(lineman.endTime)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ON WORK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Linemen On Work'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading utilities data...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Linemen On Work'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedSubstationId != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadLinemenOnWork,
              tooltip: 'Refresh linemen data',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 16),
                _buildUtilityDropdown(),
                SizedBox(height: 12),
                _buildSubstationDropdown(),
                if (_selectedSubstationId != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing linemen on work for: $_selectedUtilityName > $_selectedSubstationName',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Show restrictions info if user has locked fields
                if (!_isUtilityDropdownEnabled || !_isSubstationDropdownEnabled) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.orange[700], size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !_isUtilityDropdownEnabled && !_isSubstationDropdownEnabled
                                ? 'Location locked to your assigned utility and substation'
                                : !_isUtilityDropdownEnabled
                                    ? 'Utility locked to your assigned utility'
                                    : 'Substation locked to your assigned substation',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content Section
          Expanded(
            child: _selectedSubstationId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Please select a substation to view linemen on work',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _isLinemenLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading linemen on work...'),
                          ],
                        ),
                      )
                    : _linemenOnWork.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.engineering_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No linemen are currently on work',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'for $_selectedSubstationName',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Header with count
                              Container(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.engineering, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      '${_linemenOnWork.length} Linemen On Work',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Linemen list
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _linemenOnWork.length,
                                  itemBuilder: (context, index) {
                                    return _buildLinemanCard(_linemenOnWork[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
