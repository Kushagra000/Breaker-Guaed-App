// lib/add_device_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddDeviceScreen extends StatefulWidget {
  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _breakerNumberController = TextEditingController();
  final _substationNameController = TextEditingController();

  String? scannedMacAddress;
  bool scanning = false;

  bool get isFormValid =>
      _deviceNameController.text.isNotEmpty &&
      _breakerNumberController.text.isNotEmpty &&
      _substationNameController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _deviceNameController.addListener(_updateState);
    _breakerNumberController.addListener(_updateState);
    _substationNameController.addListener(_updateState);
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _breakerNumberController.dispose();
    _substationNameController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
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

  void _confirmDevice() {
    if (!_formKey.currentState!.validate()) return;

    if (scannedMacAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please scan the QR code to get MAC address'), backgroundColor: Colors.red.shade300),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device registered: ${_deviceNameController.text} with MAC $scannedMacAddress'),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE);

    return Scaffold(
      appBar: AppBar(title: Text('Add New Device'), backgroundColor: primaryColor),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_deviceNameController, 'Device Name', validatorMsg: 'Enter device name'),
              SizedBox(height: 24),
              _buildTextField(_breakerNumberController, 'Breaker Number', validatorMsg: 'Enter breaker number'),
              SizedBox(height: 24),
              _buildTextField(_substationNameController, 'Substation Name', validatorMsg: 'Enter substation name'),
              SizedBox(height: 36),
              ElevatedButton.icon(
                icon: scanning ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.qr_code_scanner, size: 24),
                label: Text('Scan QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isFormValid && !scanning ? _startQRScan : null,
              ),
              if (scannedMacAddress != null) ...[
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.memory, color: Colors.grey.shade700, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'MAC Address: $scannedMacAddress',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 48),
              ElevatedButton(
                child: Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scannedMacAddress != null ? Colors.green.shade700 : Colors.grey.shade400,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: scannedMacAddress != null ? _confirmDevice : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {String? validatorMsg}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      validator: validatorMsg != null ? (val) => val == null || val.isEmpty ? validatorMsg : null : null,
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
