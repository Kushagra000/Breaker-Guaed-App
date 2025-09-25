// lib/add_device_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'models/utility_hierarchy_model.dart';
import 'services/utility_service.dart';
import 'services/session_manager.dart';
import 'services/device_service.dart';

class AddDeviceScreen extends StatefulWidget {
  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  
  // State management
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  
  // API Data
  List<UtilityData> _utilities = [];
  
  // Step 1 - Location Data
  int? selectedUtilityId;
  int? selectedSubstationId;
  SubstationData? selectedSubstation;
  SubstationConnection? substationConnection;
  bool connectionDataFetched = false;  // Track if we've attempted to fetch connection data
  
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _wifiSSIDController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? selectedConnectionType;
  
  // Connection type options
  final List<String> connectionTypes = [
    'Utility Wifi',
    'SIM Wifi',  // This matches your API response
  ];
  
  // Step 2 - Device Data
  int? selectedFeederId;  // Changed from text controller to dropdown selection
  FeederData? selectedFeeder;  // Store selected feeder data
  String? scannedMacAddress;
  bool scanning = false;
  bool _isRegistering = false;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    try {
      // Check permissions first
      final hasPermission = await UtilityService.checkUtilitiesPermission();
      
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _errorMessage = 'Access denied: Only super admin users can add devices';
        });
        return;
      }
      
      // Fetch utilities data
      final utilitiesResponse = await UtilityService.getUtilitiesHierarchy();
      
      if (utilitiesResponse != null) {
        setState(() {
          _utilities = utilitiesResponse.utilities;
          _hasPermission = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasPermission = true;
          _errorMessage = 'Failed to load utilities data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _wifiSSIDController.dispose();
    _wifiPasswordController.dispose();
    _phoneNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  List<SubstationData> get filteredSubstations {
    if (selectedUtilityId == null) return [];
    return UtilityService.getSubstationsByUtilityId(_utilities, selectedUtilityId!);
  }
  
  void _onUtilityChanged(int? utilityId) {
    setState(() {
      selectedUtilityId = utilityId;
      selectedSubstationId = null;
      selectedSubstation = null;
      _clearLocationFields();
    });
  }
  
  void _onSubstationChanged(int? substationId) async {
    if (substationId != null && selectedUtilityId != null) {
      final utility = UtilityService.getUtilityById(_utilities, selectedUtilityId!);
      if (utility != null) {
        final substation = UtilityService.getSubstationById(utility, substationId);
        setState(() {
          selectedSubstationId = substationId;
          selectedSubstation = substation;
          substationConnection = null;
          connectionDataFetched = false;
          selectedFeederId = null;  // Reset feeder selection
          selectedFeeder = null;
          _clearLocationFields();
        });
        
        // Fetch substation connection data
        await _fetchSubstationConnection();
      }
    }
  }
  
  void _clearLocationFields() {
    _latitudeController.clear();
    _longitudeController.clear();
    _wifiSSIDController.clear();
    _wifiPasswordController.clear();
    _phoneNumberController.clear();
    selectedConnectionType = null;
  }
  
  Future<void> _fetchSubstationConnection() async {
    if (selectedUtilityId == null || selectedSubstationId == null) return;
    
    try {
      print('=== FETCHING CONNECTION DATA ===');
      print('Utility ID: $selectedUtilityId');
      print('Substation ID: $selectedSubstationId');
      
      final response = await DeviceService.getSubstationConnection(
        selectedUtilityId!, 
        selectedSubstationId!
      );
      
      print('Response received: ${response != null}');
      if (response != null) {
        print('Connections count: ${response.connections.length}');
        if (response.connections.isNotEmpty) {
          final conn = response.connections.first;
          print('First connection SSID: ${conn.ssid}');
          print('First connection type: ${conn.connectionType}');
        }
      }
      
      setState(() {
        substationConnection = response?.connections.isNotEmpty == true ? response!.connections.first : null;
        connectionDataFetched = true;  // Mark that we've attempted to fetch data
      });
      
      // Populate fields after state update
      _populateLocationFields();
      
      // Force UI update
      if (mounted) {
        setState(() {});
      }
      
      print('================================');
    } catch (e) {
      print('Error fetching substation connection: $e');
      // Connection data not found is not an error - user can input manually
      setState(() {
        substationConnection = null;
        connectionDataFetched = true;  // Mark that we've attempted to fetch data
        _populateLocationFields();  // Clear fields for manual input
      });
    }
  }
  
  void _populateLocationFields() {
    if (substationConnection != null) {
      // Auto-populate with existing connection data
      _latitudeController.text = substationConnection!.latitude.toString();
      _longitudeController.text = substationConnection!.longitude.toString();
      _wifiSSIDController.text = substationConnection!.ssid;
      _wifiPasswordController.text = substationConnection!.password;
      _phoneNumberController.text = substationConnection!.phoneNo;
      selectedConnectionType = substationConnection!.connectionType;
      
      print('=== POPULATING CONNECTION DATA ===');
      print('Latitude: ${substationConnection!.latitude}');
      print('Longitude: ${substationConnection!.longitude}');
      print('SSID: ${substationConnection!.ssid}');
      print('Password: ${substationConnection!.password}');
      print('Phone: ${substationConnection!.phoneNo}');
      print('Connection Type: ${substationConnection!.connectionType}');
      print('================================');
    } else {
      // Clear fields for manual input
      _clearLocationFields();
      print('No connection data - fields cleared for manual input');
    }
  }
  
  bool get isStep1Valid {
    return selectedUtilityId != null && 
           selectedSubstationId != null &&
           _latitudeController.text.isNotEmpty &&
           _longitudeController.text.isNotEmpty &&
           _wifiSSIDController.text.isNotEmpty &&
           _wifiPasswordController.text.isNotEmpty &&
           _phoneNumberController.text.isNotEmpty &&
           selectedConnectionType != null;
  }
  
  bool get isStep2Valid {
    return selectedFeederId != null &&
           scannedMacAddress != null;
  }
  
  void _nextStep() {
    if (currentStep == 0 && isStep1Valid && selectedSubstation != null) {
      setState(() {
        currentStep = 1;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (currentStep == 1) {
      setState(() {
        currentStep = 0;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _startQRScan() async {
    setState(() {
      scanning = true;
    });

    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRViewPage()),
    );

    if (scannedCode != null && scannedCode is String) {
      setState(() {
        scannedMacAddress = scannedCode;
        scanning = false;
      });
    } else {
      setState(() {
        scanning = false;
      });
    }
  }
  
  Future<void> _confirmDevice() async {
    if (!isStep2Valid) return;
    
    setState(() {
      _isRegistering = true;
    });
    
    try {
      final response = await DeviceService.registerDevice(
        substationId: selectedSubstationId!,
        feederId: selectedFeederId!,
        macId: scannedMacAddress!,
        latitude: double.tryParse(_latitudeController.text) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text) ?? 0.0,
        connectionType: selectedConnectionType!,
        ssid: _wifiSSIDController.text,
        simNumber: _phoneNumberController.text,
        password: _wifiPasswordController.text,
        utilityId: selectedUtilityId,  // Pass the utility ID
      );
      
      setState(() {
        _isRegistering = false;
      });
      
      if (response.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "${selectedFeeder?.feederName ?? 'Unknown Device'}" registered successfully!'),
            backgroundColor: Colors.green.shade400,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back or to dashboard
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${response.message}'),
            backgroundColor: Colors.red.shade400,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRegistering = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red.shade400,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE);

    // Check for loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Add New Device'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Loading utilities data...'),
            ],
          ),
        ),
      );
    }

    // Check for permission
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Add New Device'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'You do not have permission to access this feature',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check for API error
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Add New Device'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.orange.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _initializeScreen(),
                      child: Text('Retry'),
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Device - Step ${currentStep + 1}/2'),
        backgroundColor: primaryColor,
        leading: currentStep == 1 
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _previousStep,
            )
          : null,
        automaticallyImplyLeading: currentStep == 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Location', currentStep >= 0),
                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStep >= 1 ? primaryColor : Colors.grey.shade300,
                  ),
                ),
                _buildStepIndicator(1, 'Device', currentStep >= 1),
              ],
            ),
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator(int step, String label, bool isActive) {
    final primaryColor = Color(0xFF0072CE);
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStep1() {
    final primaryColor = Color(0xFF0072CE);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select utility and substation to fetch location data',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32),
          
          // Utility Dropdown
          Text(
            'Utility Company',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: selectedUtilityId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: 'Select Utility Company',
            ),
            items: _utilities.map((utility) {
              return DropdownMenuItem<int>(
                value: utility.utilityId,
                child: Text(utility.utilityName),
              );
            }).toList(),
            onChanged: _onUtilityChanged,
          ),
          SizedBox(height: 24),
          
          // Substation Dropdown
          Text(
            'Substation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: selectedSubstationId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: selectedUtilityId == null ? 'First select a utility' : 'Select Substation',
            ),
            items: filteredSubstations.map((substation) {
              return DropdownMenuItem<int>(
                value: substation.substationId,
                child: Text('${substation.substationName} (${substation.substationNumber})'),
              );
            }).toList(),
            onChanged: selectedUtilityId == null ? null : _onSubstationChanged,
          ),
          
          if (selectedSubstation != null) ...[
            SizedBox(height: 32),
            
            // Auto-populated or manual input fields
            Row(
              children: [
                Icon(
                  connectionDataFetched
                    ? (substationConnection != null ? Icons.check_circle : Icons.info_outline)
                    : Icons.hourglass_empty, 
                  color: connectionDataFetched
                    ? (substationConnection != null ? Colors.green.shade600 : Colors.orange.shade600)
                    : Colors.blue.shade600, 
                  size: 20
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    !connectionDataFetched
                      ? 'Fetching connection data...'
                      : substationConnection != null 
                        ? 'Connection data loaded automatically (you can modify if needed)'
                        : 'No existing connection data found. Please enter connection details manually.',
                    style: TextStyle(
                      fontSize: 14,
                      color: !connectionDataFetched
                        ? Colors.blue.shade700
                        : substationConnection != null 
                          ? Colors.green.shade700 
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Location fields
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _latitudeController, 
                    'Latitude',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _longitudeController, 
                    'Longitude',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildConnectionTypeDropdown(),
            SizedBox(height: 16),
            
            _buildTextField(_wifiSSIDController, 'WiFi SSID'),
            SizedBox(height: 16),
            
            _buildTextField(
              _wifiPasswordController, 
              'WiFi Password',
              obscureText: true,
            ),
            SizedBox(height: 16),
            
            _buildTextField(
              _phoneNumberController, 
              'SIM/Phone Number',
              keyboardType: TextInputType.phone,
            ),
          ],
          
          SizedBox(height: 48),
          
          // Next button
          ElevatedButton(
            onPressed: isStep1Valid ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isStep1Valid ? primaryColor : Colors.grey.shade400,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next: Device Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep2() {
    final primaryColor = Color(0xFF0072CE);
    
    // Safety check - shouldn't happen with proper navigation flow
    if (selectedUtilityId == null || selectedSubstation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Please complete Step 1 first',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _previousStep,
              child: Text('Go Back to Step 1'),
            ),
          ],
        ),
      );
    }
    
    final selectedUtility = UtilityService.getUtilityById(_utilities, selectedUtilityId!);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enter device details and scan QR code',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32),
          
          // Location summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  selectedUtility?.utilityName ?? 'Unknown Utility',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${selectedSubstation!.substationName} (${selectedSubstation!.substationNumber})',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          
          // Feeder dropdown
          _buildFeederDropdown(),
          SizedBox(height: 32),
          
          // QR Code section
          Text(
            'Device MAC Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          
          ElevatedButton.icon(
            icon: scanning 
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Icon(Icons.qr_code_scanner, size: 24),
            label: Text(
              scanning ? 'Scanning...' : 'Scan QR Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: !scanning ? _startQRScan : null,
          ),
          
          if (scannedMacAddress != null) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAC Address Scanned',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          scannedMacAddress!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 48),
          
          // Confirm button
          ElevatedButton(
            onPressed: (isStep2Valid && !_isRegistering) ? _confirmDevice : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isStep2Valid && !_isRegistering) ? Colors.green.shade700 : Colors.grey.shade400,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isRegistering
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Registering Device...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Register Device',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(
    TextEditingController controller, 
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: obscureText 
          ? IconButton(
              icon: Icon(Icons.visibility_off),
              onPressed: () {}, // Could implement show/hide password functionality
            )
          : null,
      ),
      onChanged: (value) => setState(() {}),
    );
  }
  
  Widget _buildConnectionTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedConnectionType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            hintText: 'Select Connection Type',
          ),
          items: connectionTypes.map((String connectionType) {
            return DropdownMenuItem<String>(
              value: connectionType,
              child: Text(
                connectionType == 'Utility Wifi' 
                  ? 'Utility-based Communication'
                  : 'SIM-based Communication'
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedConnectionType = newValue;
            });
          },
        ),
      ],
    );
  }
  
  /// Build feeder dropdown that shows feeders for the selected substation
  Widget _buildFeederDropdown() {
    final availableFeeders = selectedSubstation?.feeders ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Feeder',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedFeederId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            hintText: availableFeeders.isEmpty 
                ? 'No feeders available for this substation'
                : 'Choose a feeder',
          ),
          items: availableFeeders.map((feeder) {
            return DropdownMenuItem<int>(
              value: feeder.feederId,
              child: Text(
                '${feeder.feederName} (${feeder.feederNumber})',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: availableFeeders.isEmpty ? null : (int? feederId) {
            setState(() {
              selectedFeederId = feederId;
              selectedFeeder = availableFeeders.firstWhere(
                (feeder) => feeder.feederId == feederId,
                orElse: () => FeederData(
                  feederId: 0, 
                  feederName: 'Unknown', 
                  feederNumber: 'Unknown'
                ),
              );
            });
          },
          isExpanded: true,
        ),
        if (selectedFeeder != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                SizedBox(width: 8),
                Text(
                  'Feeder Number: ${selectedFeeder!.feederNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class QRViewPage extends StatefulWidget {
  @override
  State<QRViewPage> createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
            controller.stop();
            Navigator.pop(context, barcodes[0].rawValue);
          }
        },
      ),
    );
  }
}
