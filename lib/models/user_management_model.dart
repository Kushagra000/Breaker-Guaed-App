// models/user_management_model.dart
class UserManagementResponse {
  final List<UserData> users;
  final List<UserData> pendingUsers;
  final List<LinemanData> linemen;

  UserManagementResponse({
    required this.users,
    required this.pendingUsers,
    required this.linemen,
  });

  factory UserManagementResponse.fromJson(Map<String, dynamic> json) {
    return UserManagementResponse(
      users: (json['users'] as List<dynamic>? ?? [])
          .map((user) => UserData.fromJson(user))
          .toList(),
      pendingUsers: (json['pending_users'] as List<dynamic>? ?? [])
          .map((user) => UserData.fromJson(user))
          .toList(),
      linemen: (json['linemen'] as List<dynamic>? ?? [])
          .map((lineman) => LinemanData.fromJson(lineman))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'pending_users': pendingUsers.map((user) => user.toJson()).toList(),
      'linemen': linemen.map((lineman) => lineman.toJson()).toList(),
    };
  }
}

class UserData {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String designation;
  final String status;
  final int utilityId;
  final String type;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.designation,
    required this.status,
    required this.utilityId,
    required this.type,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      designation: json['designation'] ?? '',
      status: json['status'] ?? '',
      utilityId: json['utility_id'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'designation': designation,
      'status': status,
      'utility_id': utilityId,
      'type': type,
    };
  }
}

class LinemanData {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final int utilityId;
  final String type;

  LinemanData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.utilityId,
    required this.type,
  });

  factory LinemanData.fromJson(Map<String, dynamic> json) {
    return LinemanData(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? '',
      utilityId: json['utility_id'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'status': status,
      'utility_id': utilityId,
      'type': type,
    };
  }
}