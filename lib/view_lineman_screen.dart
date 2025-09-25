import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/lineman_service.dart';
import 'services/utility_service.dart';
import 'services/session_manager.dart';
import 'models/utility_hierarchy_model.dart';

class ViewLinemanScreen extends StatefulWidget {
  @override
  _ViewLinemanScreenState createState() => _ViewLinemanScreenState();
}

class _ViewLinemanScreenState extends State<ViewLinemanScreen> {
  int? _selectedUtilityId;
  String? _selectedUtilityName;
  int? _selectedSubstationId;
  String? _selectedSubstationName;
  
  List<UtilityData> _availableUtilities = [];
  List<SubstationData> _availableSubstations = [];
  List<Map<String, dynamic>> _linemen = [];
  
  bool _isUtilityDropdownEnabled = true;
  bool _isSubstationDropdownEnabled = true;
  bool _isDataLoading = true;
  bool _isLinemenLoading = false;
  
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
            
            // Automatically load linemen for predefined substation
            await _loadLinemen();
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
  
  Future<void> _loadLinemen() async {
    if (_selectedSubstationId == null) {
      _showErrorMessage('Please select a substation first');
      return;
    }
    
    print('=== VIEW LINEMAN DEBUG ===');
    print('Loading linemen for substation ID: $_selectedSubstationId');
    print('Selected utility ID: $_selectedUtilityId');
    print('User utility ID from session: ${SessionManager.utilityId}');
    print('User substation ID from session: ${SessionManager.substationId}');
    
    setState(() {
      _isLinemenLoading = true;
      _linemen = [];
    });
    
    try {
      final result = await LinemanService.getLinemanBySubstation(_selectedSubstationId!);
      
      print('API result success: ${result['success']}');
      print('API result message: ${result['message']}');
      
      if (result['success']) {
        final data = result['data'];
        if (data != null && data['linemen'] != null) {
          final List<Map<String, dynamic>> fetchedLinemen = List<Map<String, dynamic>>.from(data['linemen']);
          
          print('=== FINAL RESULTS ===');
          print('Fetched ${fetchedLinemen.length} filtered linemen from API');
          print('Original count: ${data['original_count'] ?? 'unknown'}');
          print('Filtered count: ${data['total_count'] ?? fetchedLinemen.length}');
          print('Target substation ID: ${data['substation_id'] ?? _selectedSubstationId}');
          
          // Additional verification
          if (fetchedLinemen.isNotEmpty) {
            print('=== LINEMEN TO DISPLAY ===');
            fetchedLinemen.forEach((lineman) {
              print('✓ ${lineman['name']} | Substation: ${lineman['substation_id']} | Status: ${lineman['status']}');
            });
          } else {
            print('❌ No linemen to display for substation $_selectedSubstationId');
          }
          
          setState(() {
            _linemen = fetchedLinemen;
          });
        } else {
          print('No linemen data in API response');
          setState(() {
            _linemen = [];
          });
        }
      } else {
        print('API call failed: ${result['message']}');
        _showErrorMessage(result['message']);
        setState(() {
          _linemen = [];
        });
      }
    } catch (e) {
      print('Exception in _loadLinemen: $e');
      _showErrorMessage('Error loading linemen: $e');
      setState(() {
        _linemen = [];
      });
    } finally {
      setState(() {
        _isLinemenLoading = false;
      });
    }
  }
  
  void _onUtilityChanged(int? utilityId) {
    print('Utility changed to ID: $utilityId');
    setState(() {
      _selectedUtilityId = utilityId;
      _selectedSubstationId = null; // Reset substation selection
      _availableSubstations = [];
      _linemen = []; // Clear linemen list
    });
    
    if (utilityId != null) {
      _loadSubstationsForUtility(utilityId);
    }
  }
  
  void _onSubstationChanged(int? substationId) {
    print('Substation changed to ID: $substationId');
    if (substationId != null) {
      // Find and print the selected substation details
      final selectedSubstation = _availableSubstations.firstWhere(
        (s) => s.substationId == substationId,
        orElse: () => SubstationData(
          substationId: 0,
          substationName: 'Unknown',
          substationNumber: 'Unknown',
          feeders: [],
        ),
      );
      print('Selected substation: ${selectedSubstation.substationName} (${selectedSubstation.substationNumber})');
    }
    
    setState(() {
      _selectedSubstationId = substationId;
      _linemen = []; // Clear linemen list
    });
    
    if (substationId != null) {
      _loadLinemen();
    }
  }
  
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Show phone number in a dialog with copy option
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Contact Lineman'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Phone Number:'),
                SizedBox(height: 8),
                SelectableText(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Tap the number above to copy it, then use your phone app to call.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phoneNumber));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('Copy & Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showErrorMessage('Error displaying phone number: $e');
    }
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
            Text('View Linemen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('View and contact linemen by substation', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        backgroundColor: primaryColor,
        toolbarHeight: 80,
      ),
      body: _isDataLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildUtilityDropdown(),
                  SizedBox(height: 20),
                  _buildSubstationDropdown(),
                  SizedBox(height: 30),
                  Expanded(
                    child: _buildLinemenList(),
                  ),
                ],
              ),
            ),
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
      onChanged: _selectedUtilityId == null ? null : _onSubstationChanged,
    );
  }
  
  Widget _buildLinemenList() {
    if (_selectedSubstationId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electrical_services, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select a substation to view linemen',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_isLinemenLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_linemen.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active linemen found for this substation',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLinemen,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0072CE),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Linemen (${_linemen.length})',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                 
                ],
              ),
            ),
            IconButton(
              onPressed: _loadLinemen,
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh linemen list',
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _linemen.length,
            itemBuilder: (context, index) {
              final lineman = _linemen[index];
              return _buildLinemanCard(lineman);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLinemanCard(Map<String, dynamic> lineman) {
    final String name = lineman['name']?.toString() ?? 'Unknown';
    final String phone = lineman['phone']?.toString() ?? '';
    final String email = lineman['email']?.toString() ?? '';
    final String status = lineman['status']?.toString() ??'';
    final int linemanId = lineman['lineman_id'] ?? lineman['id'] ?? 0;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: status == 'Active' ? Colors.green[100] : Colors.red[100],
              child: Icon(
                Icons.person,
                size: 30,
                color: status == 'Active' ? Colors.green[700] : Colors.red[700],
              ),
            ),
            SizedBox(width: 16),
            // Lineman details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (email.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        status == 'active' ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: status == 'active' ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 4),
                      Text(
                        status == 'active' ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: status == 'active' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (phone.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Call button
            if (phone.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => _makePhoneCall(phone),
                  icon: Icon(Icons.call, color: Colors.white),
                  tooltip: 'View phone number for $name',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
