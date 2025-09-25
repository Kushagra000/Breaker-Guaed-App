import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_profile_provider.dart';
import 'services/session_manager.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SessionManager
  await SessionManager.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProfile(),
      child: BreakerGuardApp(),
    ),
  );
}

class BreakerGuardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakerGuard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfile>(
      builder: (context, userProfile, child) {
        if (userProfile.isLoading) {
          // Show loading screen while checking session
          return Scaffold(
            backgroundColor: Colors.blue.shade900,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BreakerGuard',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Navigate based on login status
        if (userProfile.isLoggedIn) {
          return DashboardScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
