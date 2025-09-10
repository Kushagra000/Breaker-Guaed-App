import 'package:flutter/material.dart';

class UserProfile extends ChangeNotifier {
  String username = '';
  String email = '';
  String mobile = '';
  String designation = '';

  UserProfile({this.username = '', this.email = '', this.mobile = '', this.designation = ''});

  void updateProfile({required String username, required String email, required String mobile, required String designation}) {
    this.username = username;
    this.email = email;
    this.mobile = mobile;
    this.designation = designation;
    notifyListeners();
  }
}
