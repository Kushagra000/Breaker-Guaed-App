import 'package:flutter/material.dart';

class DeviceBypassedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bypassedDevices = ['Device 1', 'Device 2', 'Device 3'];
    return Scaffold(
      appBar: AppBar(title: Text('Device Bypassed')),
      body: ListView.builder(
        itemCount: bypassedDevices.length,
        itemBuilder: (ctx, idx) => ListTile(
          leading: Icon(Icons.device_unknown),
          title: Text(bypassedDevices[idx]),
        ),
      ),
    );
  }
}
