// models/assignment_models.dart
class AvailableLinemanResponse {
  final bool success;
  final String message;
  final List<AvailableLineman> linemen;

  AvailableLinemanResponse({
    required this.success,
    required this.message,
    required this.linemen,
  });

  factory AvailableLinemanResponse.fromJson(Map<String, dynamic> json) {
    return AvailableLinemanResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      linemen: json['linemen'] != null
          ? (json['linemen'] as List)
              .map((lineman) => AvailableLineman.fromJson(lineman))
              .toList()
          : [],
    );
  }
}

class AvailableLineman {
  final int id;
  final String name;
  final String phone;
  final String email;
  bool isSelected;

  AvailableLineman({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.isSelected = false,
  });

  factory AvailableLineman.fromJson(Map<String, dynamic> json) {
    return AvailableLineman(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableLineman && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SubstationUser {
  final int id;
  final String name;

  SubstationUser({
    required this.id,
    required this.name,
  });

  factory SubstationUser.fromJson(Map<String, dynamic> json) {
    return SubstationUser(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubstationUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SubstationUsersResponse {
  final List<SubstationUser> sso;
  final List<SubstationUser> je;

  SubstationUsersResponse({
    required this.sso,
    required this.je,
  });

  factory SubstationUsersResponse.fromJson(Map<String, dynamic> json) {
    return SubstationUsersResponse(
      sso: json['sso'] != null
          ? (json['sso'] as List)
              .map((user) => SubstationUser.fromJson(user))
              .toList()
          : [],
      je: json['je'] != null
          ? (json['je'] as List)
              .map((user) => SubstationUser.fromJson(user))
              .toList()
          : [],
    );
  }
}

class AssignmentRequest {
  final String purpose;
  final int substationId;
  final List<ShutdownAssignment> shutdowns;

  AssignmentRequest({
    required this.purpose,
    required this.substationId,
    required this.shutdowns,
  });

  Map<String, String> toFormData() {
    Map<String, String> formData = {
      'purpose': purpose,
      'substation': substationId.toString(),
      'shutdown_count': shutdowns.length.toString(),
    };

    for (int i = 0; i < shutdowns.length; i++) {
      final shutdown = shutdowns[i];
      final index = i + 1; // API expects 1-based indexing
      
      formData['shutdowns[$index][feeder]'] = shutdown.feederId.toString();
      formData['shutdowns[$index][officer]'] = shutdown.ssoName;  // Send name instead of ID
      formData['shutdowns[$index][je]'] = shutdown.jeName;        // Send name instead of ID
      formData['shutdowns[$index][start]'] = shutdown.startTime;
      formData['shutdowns[$index][end]'] = shutdown.endTime;
      
      // Add linemen as comma-separated list (kept for backwards compatibility)
      formData['shutdowns[$index][linemen_list]'] = shutdown.linemenIds.join(',');
    }

    // Debug logging
    print('=== ASSIGNMENT FORM DATA (Legacy) ===');
    print('Purpose: ${formData['purpose']}');
    print('Substation ID: ${formData['substation']}');
    print('Shutdown Count: ${formData['shutdown_count']}');
    for (int i = 1; i <= shutdowns.length; i++) {
      print('Shutdown $i:');
      print('  Feeder ID: ${formData['shutdowns[$i][feeder]']}');
      print('  SSO Name: ${formData['shutdowns[$i][officer]']}');
      print('  JE Name: ${formData['shutdowns[$i][je]']}');
      print('  Start Time: ${formData['shutdowns[$i][start]']}');
      print('  End Time: ${formData['shutdowns[$i][end]']}');
      print('  Linemen List: ${formData['shutdowns[$i][linemen_list]']}');
    }
    print('====================================');

    return formData;
  }
}

class ShutdownAssignment {
  final int feederId;
  final int ssoId;
  final int jeId;
  final String ssoName;   // Added SSO name
  final String jeName;    // Added JE name
  final List<int> linemenIds;
  final String startTime;
  final String endTime;

  ShutdownAssignment({
    required this.feederId,
    required this.ssoId,
    required this.jeId,
    required this.ssoName,
    required this.jeName,
    required this.linemenIds,
    required this.startTime,
    required this.endTime,
  });
}