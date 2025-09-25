// models/management_data_model.dart
class ManagementDataResponse {
  final bool success;
  final ManagementData data;

  ManagementDataResponse({
    required this.success,
    required this.data,
  });

  factory ManagementDataResponse.fromJson(Map<String, dynamic> json) {
    return ManagementDataResponse(
      success: json['success'] ?? false,
      data: ManagementData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class ManagementData {
  final List<RoleData> roles;
  final List<DesignationData> designations;
  final List<DepartmentData> departments;
  final List<dynamic> utilities;
  final List<dynamic> substations;
  final List<dynamic> ssoUsers;
  final List<dynamic> jeUsers;
  final bool isSuperadmin;

  ManagementData({
    required this.roles,
    required this.designations,
    required this.departments,
    required this.utilities,
    required this.substations,
    required this.ssoUsers,
    required this.jeUsers,
    required this.isSuperadmin,
  });

  factory ManagementData.fromJson(Map<String, dynamic> json) {
    return ManagementData(
      roles: (json['roles'] as List? ?? [])
          .map((role) => RoleData.fromJson(role))
          .toList(),
      designations: (json['designations'] as List? ?? [])
          .map((designation) => DesignationData.fromJson(designation))
          .toList(),
      departments: (json['departments'] as List? ?? [])
          .map((department) => DepartmentData.fromJson(department))
          .toList(),
      utilities: json['utilities'] as List? ?? [],
      substations: json['substations'] as List? ?? [],
      ssoUsers: json['sso_users'] as List? ?? [],
      jeUsers: json['je_users'] as List? ?? [],
      isSuperadmin: json['is_superadmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles.map((role) => role.toJson()).toList(),
      'designations': designations.map((designation) => designation.toJson()).toList(),
      'departments': departments.map((department) => department.toJson()).toList(),
      'utilities': utilities,
      'substations': substations,
      'sso_users': ssoUsers,
      'je_users': jeUsers,
      'is_superadmin': isSuperadmin,
    };
  }
}

class RoleData {
  final int roleId;
  final String roleName;

  RoleData({
    required this.roleId,
    required this.roleName,
  });

  factory RoleData.fromJson(Map<String, dynamic> json) {
    return RoleData(
      roleId: json['role_id'],
      roleName: json['role_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_name': roleName,
    };
  }
}

class DesignationData {
  final int designationId;
  final String designationName;

  DesignationData({
    required this.designationId,
    required this.designationName,
  });

  factory DesignationData.fromJson(Map<String, dynamic> json) {
    return DesignationData(
      designationId: json['designation_id'],
      designationName: json['designation_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'designation_id': designationId,
      'designation_name': designationName,
    };
  }
}

class DepartmentData {
  final int departmentId;
  final String departmentName;

  DepartmentData({
    required this.departmentId,
    required this.departmentName,
  });

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      departmentId: json['department_id'],
      departmentName: json['department_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'department_name': departmentName,
    };
  }
}