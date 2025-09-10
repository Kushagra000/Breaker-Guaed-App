import 'package:flutter/material.dart';
import 'lineman_on_work_screen.dart';
import 'device_bypassed_screen.dart';
import 'work_history_screen.dart';

class ActiveTaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(double.infinity, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Active Tasks')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LinemanOnWorkScreen()));
              },
              child: Text('Lineman on Work', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceBypassedScreen()));
              },
              child: Text('Device Bypassed', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkHistoryScreen()));
              },
              child: Text('Work History', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
