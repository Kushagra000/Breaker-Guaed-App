import 'package:flutter/material.dart';
import 'lineman_screen.dart';
import 'active_task_screen.dart';
import 'assign_lineman_screen.dart';
import 'view_lineman_screen.dart';
import 'remove_assigned_lineman_screen.dart';

class ManageWorkScreen extends StatelessWidget {
  final String userName = 'User'; // Replace with actual user name

  @override
  Widget build(BuildContext context) {
    final lightSkin = Color(0xFFF5F0E6); // Light skin background color
    final blueColor = Color(0xFF0072CE); // Kesko Blue

    // Gradient colors for buttons
    final gradients = [
      [Colors.red.shade400, Colors.red.shade200],
      [Colors.orange.shade400, Colors.orange.shade200],
      [Colors.green.shade400, Colors.green.shade200],
      [Colors.purple.shade400, Colors.purple.shade200],
    ];

    final List<_ButtonData> buttons = [
      _ButtonData(
          label: 'Add Lineman',
          icon: Icons.engineering,
          page: LinemanScreen(),
          gradient: gradients[0]),
      _ButtonData(
          label: 'Active Task',
          icon: Icons.task,
          page: ActiveTaskScreen(),
          gradient: gradients[1]),
      _ButtonData(
          label: 'AssignLineman',
          icon: Icons.person_add,
          page: AssignLinemanScreen(),
          gradient: gradients[2]),
      _ButtonData(
          label: 'ViewLineman',
          icon: Icons.person_search,
          page: ViewLinemanScreen(),
          gradient: gradients[3]),
    ];

    return Scaffold(
      backgroundColor: lightSkin,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: lightSkin,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome back, you\'ve been missed!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hello,',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: blueColor),
                  ),
                  // Decorative underline
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [blueColor.withOpacity(0.5), blueColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: buttons.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2),
          itemBuilder: (context, i) {
            final btn = buttons[i];
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.black45,
              ),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => btn.page));
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: btn.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(btn.icon, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        btn.label,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: blueColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0, // Home selected
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.remove_circle), label: 'Remove AssignLineman'),
        ],
        onTap: (idx) {
         if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => RemoveAssignedLinemanScreen()));
          }
        },
      ),
    );
  }
}

// Helper class to hold button details
class _ButtonData {
  final String label;
  final IconData icon;
  final Widget page;
  final List<Color> gradient;

  _ButtonData({
    required this.label,
    required this.icon,
    required this.page,
    required this.gradient,
  });
}
