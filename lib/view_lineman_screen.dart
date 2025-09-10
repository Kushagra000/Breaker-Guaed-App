import 'package:flutter/material.dart';

class ViewLinemanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final linemanDetails = [
      {'name': 'John Doe', 'status': 'Active'},
      {'name': 'Jane Smith', 'status': 'On Task'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text('View Lineman')),
      body: ListView(
        children: linemanDetails
            .map((l) => ListTile(
                  title: Text(l['name'] ?? ''),
                  subtitle: Text('Status: ${l['status'] ?? ''}'),
                ))
            .toList(),
      ),
    );
  }
}
