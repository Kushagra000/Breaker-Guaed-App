// activity_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/activity_log_model.dart';
import 'models/utility_hierarchy_model.dart';
import 'services/activity_logs_service.dart';
import 'services/utility_service.dart';
import 'services/session_manager.dart';
import 'user_profile_provider.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  // Data storage
  List<ActivityLog> _allActivityLogs = []; // All logs from API
  List<ActivityLog> _filteredActivityLogs = []; // After utility filter
  List<ActivityLog> _displayedActivityLogs = []; // Currently displayed (paginated)
  
  // UI state
  bool _isLoading = true;
  String? _error;
  
  // Filtering
  List<UtilityData> _utilities = [];
  String? _selectedUtilityName; // null means "All Utilities"
  bool _canFilterAllUtilities = false;
  String _userUtilityName = '';
  
  // Pagination
  int _currentPage = 1;
  final int _pageSize = 15;
  bool _hasMoreData = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMoreData) {
        _loadMoreLogs();
      }
    }
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check permissions
      final canView = await ActivityLogsService.canViewActivityLogs();
      if (!canView) {
        setState(() {
          _error = 'Access denied: You do not have permission to view activity logs';
          _isLoading = false;
        });
        return;
      }

      // Get user info
      await SessionManager.initialize();
      _canFilterAllUtilities = ActivityLogsService.canFilterAllUtilities();
      _userUtilityName = ActivityLogsService.getUserUtilityName();
      
      print('Can filter all utilities: $_canFilterAllUtilities');
      print('User utility name: $_userUtilityName');

      // Set initial filter for regular admin users
      if (!_canFilterAllUtilities && _userUtilityName.isNotEmpty) {
        _selectedUtilityName = _userUtilityName;
        print('Setting initial filter to user utility: $_selectedUtilityName');
      }

      // Load utilities for dropdown (if super admin)
      if (_canFilterAllUtilities) {
        await _loadUtilities();
      }

      // Load all activity logs
      await _loadAllActivityLogs();

    } catch (e) {
      setState(() {
        _error = 'Error initializing screen: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUtilities() async {
    try {
      final response = await UtilityService.getUtilitiesHierarchy();
      if (response != null) {
        setState(() {
          _utilities = response.utilities;
        });
        print('Loaded ${_utilities.length} utilities for dropdown');
      }
    } catch (e) {
      print('Error loading utilities: $e');
    }
  }

  Future<void> _loadAllActivityLogs() async {
    try {
      print('Fetching all activity logs from API...');
      
      final response = await ActivityLogsService.getAllActivityLogs();
      
      if (response != null && response.logs.isNotEmpty) {
        print('Received ${response.logs.length} activity logs from API');
        setState(() {
          _allActivityLogs = response.logs;
          _isLoading = false;
        });
        
        // Apply filtering and pagination
        _applyFilterAndPagination();
      } else {
        print('No activity logs received from API');
        setState(() {
          _allActivityLogs = [];
          _isLoading = false;
        });
        _applyFilterAndPagination();
      }
    } catch (e) {
      print('Error loading activity logs: $e');
      setState(() {
        _error = 'Error loading activity logs: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilterAndPagination() {
    print('Applying filter: $_selectedUtilityName');
    print('Total logs before filter: ${_allActivityLogs.length}');
    
    // Step 1: Apply utility filter
    if (_selectedUtilityName == null || _selectedUtilityName == 'All Utilities') {
      // Show all logs (super admin only)
      _filteredActivityLogs = List.from(_allActivityLogs);
      print('Showing all logs (no filter)');
    } else {
      // Filter by utility name (case-insensitive)
      _filteredActivityLogs = _allActivityLogs.where((log) {
        final logUtility = log.utilityName.toLowerCase().trim();
        final selectedUtility = _selectedUtilityName!.toLowerCase().trim();
        return logUtility.contains(selectedUtility) || selectedUtility.contains(logUtility);
      }).toList();
      print('Filtered to ${_filteredActivityLogs.length} logs for utility: $_selectedUtilityName');
    }
    
    // Step 2: Reset pagination
    _currentPage = 1;
    _updateDisplayedLogs();
  }

  void _updateDisplayedLogs() {
    final totalLogs = _filteredActivityLogs.length;
    final endIndex = _currentPage * _pageSize;
    
    if (endIndex >= totalLogs) {
      // Show all remaining logs
      _displayedActivityLogs = List.from(_filteredActivityLogs);
      _hasMoreData = false;
    } else {
      // Show logs up to current page
      _displayedActivityLogs = _filteredActivityLogs.sublist(0, endIndex);
      _hasMoreData = true;
    }
    
    print('Page $_currentPage: Displaying ${_displayedActivityLogs.length} of $totalLogs logs, hasMore: $_hasMoreData');
    
    setState(() {});
  }

  void _loadMoreLogs() {
    if (!_hasMoreData) return;
    
    print('Loading more logs...');
    _currentPage++;
    _updateDisplayedLogs();
  }

  void _onUtilityChanged(String? utilityName) {
    print('Utility filter changed from "$_selectedUtilityName" to "$utilityName"');
    
    setState(() {
      _selectedUtilityName = utilityName;
    });
    
    _applyFilterAndPagination();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE);

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading activity logs...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 24),
              ElevatedButton(onPressed: _initializeScreen, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildFilterSection(),
        _buildResultsInfo(),
        Expanded(child: _buildActivityLogsList()),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Utility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          if (_canFilterAllUtilities) _buildUtilityDropdown() else _buildFixedUtilityDisplay(),
        ],
      ),
    );
  }

  Widget _buildUtilityDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedUtilityName,
      decoration: InputDecoration(
        labelText: 'Select Utility',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('All Utilities')),
        ..._utilities.map((utility) => DropdownMenuItem<String?>(
          value: utility.utilityName,
          child: Text(utility.utilityName),
        )),
      ],
      onChanged: _onUtilityChanged,
      isExpanded: true,
    );
  }

  Widget _buildFixedUtilityDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: Row(
        children: [
          Icon(Icons.business, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(child: Text(_userUtilityName.isNotEmpty ? _userUtilityName : 'Your Utility', style: TextStyle(fontSize: 16))),
          Icon(Icons.lock, color: Colors.grey[600], size: 20),
        ],
      ),
    );
  }

  Widget _buildResultsInfo() {
    if (_isLoading) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text('Showing ${_displayedActivityLogs.length} of ${_filteredActivityLogs.length} logs', 
               style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          if (_hasMoreData) ...[
            SizedBox(width: 8),
            Text('• Scroll for more', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityLogsList() {
    if (_displayedActivityLogs.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Activity Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              _selectedUtilityName == null ? 'No activity logs found.' : 'No activity logs found for "$_selectedUtilityName".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllActivityLogs,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _displayedActivityLogs.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _displayedActivityLogs.length) {
            final log = _displayedActivityLogs[index];
            return _buildActivityLogCard(log);
          } else {
            return _buildLoadMoreIndicator();
          }
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (_hasMoreData) ...[
            Text('Scroll to load more logs...', style: TextStyle(color: Colors.grey[600])),
          ] else ...[
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(height: 8),
            Text('All logs loaded', style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityLogCard(ActivityLog log) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF0072CE),
                  child: Text(
                    log.performedBy.isNotEmpty ? log.performedBy[0].toUpperCase() : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.performedBy, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(log.userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      SizedBox(height: 4),
                      Text(log.formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(log.action, style: TextStyle(fontSize: 14)),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(child: Text(log.utilityName, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                if (log.substationName.isNotEmpty && log.substationName != '-') ...[
                  SizedBox(width: 12),
                  Icon(Icons.electrical_services, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(log.substationName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}