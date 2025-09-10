import 'package:flutter/material.dart';

class AssignLinemanScreen extends StatefulWidget {
  @override
  _AssignLinemanScreenState createState() => _AssignLinemanScreenState();
}

class _AssignLinemanScreenState extends State<AssignLinemanScreen> {
  final List<String> feederLocations = ['Feeder A', 'Feeder B', 'Feeder C'];
  String? selectedFeeder;

  final TextEditingController searchController = TextEditingController();

  final List<_Lineman> allLinemen = [
    _Lineman(name: 'John Doe', mobile: '1234567890'),
    _Lineman(name: 'Jane Smith', mobile: '0987654321'),
    _Lineman(name: 'Alex Lineman', mobile: '1112223333'),
    _Lineman(name: 'Chris Brown', mobile: '4445556666'),
  ];

  List<_Lineman> filteredLinemen = [];

  final Set<_Lineman> selectedLinemen = {};

  // Duration selection
  int assignHours = 0;
  int assignMinutes = 0;

  @override
  void initState() {
    super.initState();
    filteredLinemen = List.from(allLinemen);

    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      setState(() {
        filteredLinemen = allLinemen.where((l) =>
            l.name.toLowerCase().contains(query)
            || l.mobile.contains(query)
        ).toList();
      });
    });
  }

  

  bool get canAssign =>
      selectedFeeder != null &&
      selectedLinemen.isNotEmpty &&
      (assignHours > 0 || assignMinutes > 0);

void _showDurationPicker() {
  int tempHours = assignHours;
  int tempMinutes = assignMinutes;

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 250,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Select Assign Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) => tempHours = index,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 23) return null;
                        return Center(child: Text('$index h'));
                      },
                      childCount: 24,
                    ),
                  ),
                ),
                SizedBox(width: 30),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) => tempMinutes = index,
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 59) return null;
                        return Center(child: Text('$index m'));
                      },
                      childCount: 60,
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (tempHours == 0 && tempMinutes == 0) {
                        // Possibly show a warning
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Duration cannot be zero'))
                        );
                        return;
                      }
                      setState(() {
                        assignHours = tempHours;
                        assignMinutes = tempMinutes;
                      });
                      Navigator.pop(context);
                      _assignLineman();
                    },
                    child: Text('OK'))
              ],
            )
          ],
        ),
      );
    });
}

  void _assignLineman() {
    if (!canAssign) return;

    // Here you would do your backend call or state update
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Assigned ${selectedLinemen.length} lineman(s) to $selectedFeeder for ${assignHours}h ${assignMinutes}m')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Lineman')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Feeder location dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  labelText: 'Select Feeder Location',
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              value: selectedFeeder,
              items: feederLocations
                  .map((fl) =>
                      DropdownMenuItem(value: fl, child: Text(fl)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedFeeder = val;
                });
              },
              validator: (val) =>
                  val == null ? 'Please select a feeder location' : null,
            ),
            SizedBox(height: 16),

            // Search lineman input
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search Lineman',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16),

            // List of linemen with checkboxes
            Expanded(
              child: filteredLinemen.isEmpty
                  ? Center(child: Text('No linemen found'))
                  : ListView.builder(
                      itemCount: filteredLinemen.length,
                      itemBuilder: (ctx, idx) {
                        final lineman = filteredLinemen[idx];
                        final isSelected =
                            selectedLinemen.contains(lineman);
                        return CheckboxListTile(
                          title: Text('${lineman.name} (${lineman.mobile})'),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true)
                                selectedLinemen.add(lineman);
                              else
                                selectedLinemen.remove(lineman);
                            });
                          },
                        );
                      },
                    ),
            ),

            // Assign button
            SizedBox(
              width: double.infinity,
              height: 50,
              child:ElevatedButton(
  child: Text('Assign'),
  onPressed: () {
    if (selectedFeeder == null || selectedLinemen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select feeder location and lineman first'))
      );
      return;
    }
    _showDurationPicker();
  },
),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lineman {
  final String name;
  final String mobile;
  _Lineman({required this.name, required this.mobile});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Lineman &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          mobile == other.mobile;

  @override
  int get hashCode => name.hashCode ^ mobile.hashCode;
}
