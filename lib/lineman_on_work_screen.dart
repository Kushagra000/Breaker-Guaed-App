import 'package:flutter/material.dart';

class LinemanOnWorkScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final linemenWorking = ['John Doe', 'Jane Smith'];
    return Scaffold(
      appBar: AppBar(title: Text('Lineman On Work')),
      body: ListView.builder(
        itemCount: linemenWorking.length,
        itemBuilder: (ctx, idx) => ListTile(
          leading: Icon(Icons.engineering),
          title: Text(linemenWorking[idx]),
        ),
      ),
    );
  }
}
