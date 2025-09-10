import 'package:flutter/material.dart';

class WorkHistoryScreen extends StatelessWidget {
  final List<_WorkHistoryItem> workHistoryItems = [
    _WorkHistoryItem(
      substation: 'Lab_white',
      breakerNumber: 'Breaker: 6',
      assignedDate: '03/09/2025 15:28',
      assignedBy: 'Himanshu/Junior Engineer (JE)/7668151892',
      assignedTo: 'Himanshu',
      completionStatus: 'Removed: Not completed yet',
    ),
    _WorkHistoryItem(
      substation: 'Main_Grid',
      breakerNumber: 'Breaker: 4',
      assignedDate: '01/09/2025 10:15',
      assignedBy: 'Sakshi/Senior Engineer (SE)/9881122334',
      assignedTo: 'Rajesh',
      completionStatus: 'Completed: Yes',
    ),
    _WorkHistoryItem(
      substation: 'Sector_12',
      breakerNumber: 'Breaker: 10',
      assignedDate: '28/08/2025 09:00',
      assignedBy: 'Nina/Junior Engineer (JE)/8776655443',
      assignedTo: 'Sameer',
      completionStatus: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final greenLight = Colors.green.shade50;
    final orangeLight = Colors.orange.shade50;

    return Scaffold(
      appBar: AppBar(
        title: Text('Work History'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: workHistoryItems.length,
        itemBuilder: (context, index) {
          final item = workHistoryItems[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.only(bottom: 20),
            elevation: 6,
            shadowColor: Colors.grey.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top section background with padding and subtle rounded corners
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                                text: 'Substation: ',
                                style: TextStyle(color: Colors.blue.shade800)),
                            TextSpan(text: item.substation),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                                text: 'Breaker Number: ',
                                style: TextStyle(color: Colors.blue.shade800)),
                            TextSpan(text: item.breakerNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Assignment details section with subtle green background and padding
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: greenLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.assignment_turned_in,
                            color: Colors.green.shade700),
                        SizedBox(width: 10),
                        Text('ASSIGNMENT DETAILS',
                            style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ]),
                      SizedBox(height: 15),
                      Text('Assigned: ${item.assignedDate}',
                          style: TextStyle(
                              color: Colors.green.shade900.withOpacity(0.85))),
                      SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.green.shade900),
                          children: [
                            TextSpan(
                                text: 'Assigned By: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: item.assignedBy),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('To: ${item.assignedTo}',
                          style: TextStyle(color: Colors.green.shade900)),
                    ],
                  ),
                ),
                // Completion status header with icon
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: orangeLight,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(0),
                      top: Radius.circular(0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.deepOrange.shade700),
                      SizedBox(width: 10),
                      Text(
                        'COMPLETION STATUS',
                        style: TextStyle(
                            color: Colors.deepOrange.shade900,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                // Completion status message with a bit more padding
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: orangeLight,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    item.completionStatus,
                    style: TextStyle(
                      color: Colors.deepOrange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add bypassed devices navigation functionality here
        },
        label: Text('Show Bypassed Devices'),
        icon: Icon(Icons.device_unknown),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }
}

class _WorkHistoryItem {
  final String substation;
  final String breakerNumber;
  final String assignedDate;
  final String assignedBy;
  final String assignedTo;
  final String completionStatus;

  _WorkHistoryItem({
    required this.substation,
    required this.breakerNumber,
    required this.assignedDate,
    required this.assignedBy,
    required this.assignedTo,
    required this.completionStatus,
  });
}
