// models/lineman_on_work_model.dart
class LinemanOnWorkResponse {
  final bool success;
  final List<LinemanOnWork> linemen;

  LinemanOnWorkResponse({
    required this.success,
    required this.linemen,
  });

  factory LinemanOnWorkResponse.fromJson(Map<String, dynamic> json) {
    return LinemanOnWorkResponse(
      success: json['success'] ?? false,
      linemen: (json['linemen'] as List<dynamic>? ?? [])
          .map((item) => LinemanOnWork.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'linemen': linemen.map((item) => item.toJson()).toList(),
    };
  }
}

class LinemanOnWork {
  final int id;
  final String name;
  final String phone;
  final String email;
  final int shutdownId;
  final String purpose;
  final String startTime;
  final String endTime;

  LinemanOnWork({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.shutdownId,
    required this.purpose,
    required this.startTime,
    required this.endTime,
  });

  factory LinemanOnWork.fromJson(Map<String, dynamic> json) {
    return LinemanOnWork(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      shutdownId: json['shutdown_id'] ?? 0,
      purpose: json['purpose'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'shutdown_id': shutdownId,
      'purpose': purpose,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}