import 'package:flutter/material.dart';

class LinemanScreen extends StatefulWidget {
  @override
  _LinemanScreenState createState() => _LinemanScreenState();
}

class _LinemanScreenState extends State<LinemanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _fatherNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }

  void _saveLineman() {
    if (_formKey.currentState!.validate()) {
      // Add save logic here (API call or state update)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lineman saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF0072CE);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add new User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Want to Add a new Lineman Data', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        backgroundColor: primaryColor,
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Lineman Name',
                icon: Icons.person,
                validatorMsg: 'Please enter Lineman Name',
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validatorMsg: 'Please enter Mobile Number',
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _fatherNameController,
                label: 'Father\'s Name',
                icon: Icons.person_outline,
                validatorMsg: 'Please enter Father\'s Name',
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _saveLineman,
                  child: Text(
                    'Save Lineman',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String validatorMsg,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (val) => val == null || val.isEmpty ? validatorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
