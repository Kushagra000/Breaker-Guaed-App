import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/work_history_model.dart';
import 'models/utility_hierarchy_model.dart' as utility;
import 'services/work_history_service.dart';
import 'services/utility_service.dart';
import 'user_profile_provider.dart';

class WorkHistoryScreen extends StatefulWidget {
  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  List<ShutdownData> shutdowns = [];
  List<utility.UtilityData> utilities = [];
  List<utility.SubstationData> availableSubstations = [];
  int? selectedUtilityId;
  int? selectedSubstationId;
  bool isLoading = true;
  bool isUtilityLocked = false;
  bool isSubstationLocked = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProfile = Provider.of<UserProfile>(context, listen: false);
      
      // Load utilities hierarchy
      final utilitiesResponse = await UtilityService.getUtilitiesHierarchy();
      if (utilitiesResponse != null) {
        utilities = utilitiesResponse.utilities;
      }

      // Load work history data
      final workHistoryResponse = await WorkHistoryService.getWorkHistory();
      if (workHistoryResponse != null) {
        shutdowns = workHistoryResponse.shutdowns;
        // Note: availableSubstations will be set from utilities hierarchy
      }

      // Check if current user has utility/substation locked
      if (userProfile.utilityId > 0) {
        selectedUtilityId = userProfile.utilityId;
        isUtilityLocked = true;
        _updateSubstationsForUtility(selectedUtilityId!);
      }

      // Check if user has substation assigned
      if (userProfile.user?.substationId != null && userProfile.user!.substationId > 0) {
        selectedSubstationId = userProfile.user!.substationId;
        isSubstationLocked = true;
      }

    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load work history: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateSubstationsForUtility(int utilityId) {
    final utilityItem = utilities.firstWhere(
      (u) => u.utilityId == utilityId,
      orElse: () => utility.UtilityData(utilityId: 0, utilityName: '', substations: []),
    );
    setState(() {
      availableSubstations = utilityItem.substations;
      if (!isSubstationLocked) {
        selectedSubstationId = null; // Reset substation when utility changes
      }
    });
  }

  List<ShutdownData> get filteredShutdowns {
    List<ShutdownData> filtered = shutdowns;
    
    if (selectedUtilityId != null) {
      filtered = WorkHistoryService.filterShutdownsByUtility(filtered, selectedUtilityId);
    }
    
    if (selectedSubstationId != null) {
      filtered = WorkHistoryService.filterShutdownsBySubstation(filtered, selectedSubstationId);
    }
    
    return filtered;
  }

  String _getUtilityName(int utilityId) {
    final utilityItem = utilities.firstWhere(
      (u) => u.utilityId == utilityId,
      orElse: () => utility.UtilityData(utilityId: 0, utilityName: 'Unknown', substations: []),
    );
    return utilityItem.utilityName;
  }

  Color _getStatusColor(String status) {
    return WorkHistoryService.getStatusColor(status);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'ongoing':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work History'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorScreen()
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(child: _buildHistoryList()),
                  ],
                ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            errorMessage!,
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Options:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              // Utility Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utility:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedUtilityId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Utility',
                      enabled: !isUtilityLocked,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Utilities'),
                      ),
                      ...utilities.map((utility) {
                        return DropdownMenuItem<int?>(
                          value: utility.utilityId,
                          child: Text(utility.utilityName),
                        );
                      }).toList(),
                    ],
                    onChanged: isUtilityLocked
                        ? null
                        : (value) {
                            setState(() {
                              selectedUtilityId = value;
                              if (value != null) {
                                _updateSubstationsForUtility(value);
                              } else {
                                availableSubstations = [];
                                selectedSubstationId = null;
                              }
                            });
                          },
                  ),
                  if (isUtilityLocked)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '🔒 Utility is locked to your assigned utility',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              // Substation Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Substation:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedSubstationId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Substation',
                      enabled: !isSubstationLocked && availableSubstations.isNotEmpty,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Substations'),
                      ),
                      ...availableSubstations.map((substation) {
                        return DropdownMenuItem<int?>(
                          value: substation.substationId,
                          child: Text(substation.substationName),
                        );
                      }).toList(),
                    ],
                    onChanged: isSubstationLocked || availableSubstations.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedSubstationId = value;
                            });
                          },
                  ),
                  if (isSubstationLocked)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '🔒 Substation is locked to your assigned substation',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (!isSubstationLocked && selectedUtilityId == null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Please select a utility first',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (filteredShutdowns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No work history found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredShutdowns.length,
      itemBuilder: (context, index) {
        final shutdown = filteredShutdowns[index];
        return _buildShutdownCard(shutdown);
      },
    );
  }

  Widget _buildShutdownCard(ShutdownData shutdown) {
    final statusColor = _getStatusColor(shutdown.status);
    final statusIcon = _getStatusIcon(shutdown.status);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shutdown.purpose}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        shutdown.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Location details
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCATION DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.business, 'Utility', _getUtilityName(shutdown.utilityId)),
                _buildInfoRow(Icons.electrical_services, 'Substation', '${shutdown.substationName} (${shutdown.substationNumber})'),
                _buildInfoRow(Icons.power, 'Feeder', '${shutdown.feederName} (${shutdown.feederNumber})'),
              ],
            ),
          ),
          // Personnel details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONNEL DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.supervisor_account, 'SSO', shutdown.sso),
                _buildInfoRow(Icons.engineering, 'JE', shutdown.je),
                if (shutdown.linemen.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    'Linemen:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  ...shutdown.linemen.map((lineman) => 
                    Padding(
                      padding: EdgeInsets.only(left: 24, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lineman.name} (${lineman.phone})',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ],
            ),
          ),
          // Timing details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIMING DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Start Time', WorkHistoryService.formatDateTime(shutdown.startTime)),
                _buildInfoRow(Icons.access_time_filled, 'End Time', WorkHistoryService.formatDateTime(shutdown.endTime)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
