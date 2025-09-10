import 'package:flutter/material.dart';

class RemoveAssignedLinemanScreen extends StatefulWidget {
  @override
  State<RemoveAssignedLinemanScreen> createState() => _RemoveAssignedLinemanScreenState();
}

class _RemoveAssignedLinemanScreenState extends State<RemoveAssignedLinemanScreen> {
  // Dummy list of assigned linemen
  List<String> assignedLinemen = ['John Doe', 'Jane Smith', 'Alex Lineman'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Remove Assigned Lineman')),
      body: ListView.builder(
        itemCount: assignedLinemen.length,
        itemBuilder: (ctx, idx) {
          final lineman = assignedLinemen[idx];
          return Dismissible(
            key: Key(lineman),
            background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
            onDismissed: (direction) {
              setState(() {
                assignedLinemen.removeAt(idx);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$lineman removed from assignments'))
              );
            },
            child: ListTile(
              title: Text(lineman),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    assignedLinemen.removeAt(idx);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$lineman removed from assignments'))
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
