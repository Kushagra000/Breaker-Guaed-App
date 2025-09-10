import 'package:flutter/material.dart';

class ApproveRejectScreen extends StatefulWidget {
  @override
  State<ApproveRejectScreen> createState() => _ApproveRejectScreenState();
}

class _ApproveRejectScreenState extends State<ApproveRejectScreen> {
  List<JEUser> users = [
    JEUser(name: "Suresh", mobile: "7668151892", designation: "Junior Engineer (JE)", status: "pending"),
    JEUser(name: "Rajesh", mobile: "9853441234", designation: "Junior Engineer (JE)", status: "pending"),
    JEUser(name: "Nina", mobile: "8776655443", designation: "Junior Engineer (JE)", status: "pending"),
  ];

  void _showConfirmBox(int idx, bool isApprove) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isApprove ? "Approve?" : "Reject?"),
        content: Text(isApprove
            ? "Are you sure you want to approve ${users[idx].name}?"
            : "Are you sure you want to reject ${users[idx].name}?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Confirm"),
            style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red),
            onPressed: () {
              setState(() {
                users[idx].status = isApprove ? "approved" : "rejected";
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "${users[idx].name} ${isApprove ? "approved" : "rejected"}")));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Approve / Reject')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, idx) {
          final user = users[idx];
          return Card(
            margin: EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${user.name}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("Mobile: ${user.mobile}", style: TextStyle(fontSize: 16)),
                  Text("Designation: ${user.designation}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 14),
                  if (user.status == "pending")
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.check, color: Colors.white),
                            label: Text("Approve"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () => _showConfirmBox(idx, true),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.close, color: Colors.white),
                            label: Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => _showConfirmBox(idx, false),
                          ),
                        ),
                      ],
                    ),
                  if (user.status == "approved")
                    Text("Approved", style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  if (user.status == "rejected")
                    Text("Rejected", style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class JEUser {
  String name;
  String mobile;
  String designation;
  String status;
  JEUser({required this.name, required this.mobile, required this.designation, required this.status});
}
