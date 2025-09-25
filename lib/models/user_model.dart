class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String designation;
  final String roleName;
  final String departmentName;
  final String utilityName;
  final int utilityId;
  final int substationId;
  final bool isSuperadmin;
  final String sessionId;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.designation,
    required this.roleName,
    required this.departmentName,
    required this.utilityName,
    required this.utilityId,
    required this.substationId,
    required this.isSuperadmin,
    required this.sessionId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      designation: json['designation'] ?? '',
      roleName: json['role_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      utilityName: json['utility_name'] ?? '',
      utilityId: json['utility_id'] ?? 0,
      substationId: json['substation_id'] ?? 0,
      isSuperadmin: json['is_superadmin'] ?? false,
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'designation': designation,
      'role_name': roleName,
      'department_name': departmentName,
      'utility_name': utilityName,
      'utility_id': utilityId,
      'substation_id': substationId,
      'is_superadmin': isSuperadmin,
      'session_id': sessionId,
    };
  }

  UserModel copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? designation,
    String? roleName,
    String? departmentName,
    String? utilityName,
    int? utilityId,
    int? substationId,
    bool? isSuperadmin,
    String? sessionId,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      roleName: roleName ?? this.roleName,
      departmentName: departmentName ?? this.departmentName,
      utilityName: utilityName ?? this.utilityName,
      utilityId: utilityId ?? this.utilityId,
      substationId: substationId ?? this.substationId,
      isSuperadmin: isSuperadmin ?? this.isSuperadmin,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? redirectUrl;
  final UserModel? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.redirectUrl,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      redirectUrl: json['redirect_url'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}