// models/activity_log_model.dart
class ActivityLogResponse {
  final List<ActivityLog> logs;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;
  final bool? hasNext;
  final bool? hasPrevious;

  ActivityLogResponse({
    required this.logs,
    this.totalCount,
    this.currentPage,
    this.totalPages,
    this.hasNext,
    this.hasPrevious,
  });

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) {
    return ActivityLogResponse(
      logs: (json['logs'] as List)
          .map((log) => ActivityLog.fromJson(log))
          .toList(),
      totalCount: json['total_count'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      hasNext: json['has_next'],
      hasPrevious: json['has_previous'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((log) => log.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}

class ActivityLog {
  final int id;
  final String performedBy;
  final String userEmail;
  final String action;
  final String performedAt;
  final String utilityName;
  final String substationName;

  ActivityLog({
    required this.id,
    required this.performedBy,
    required this.userEmail,
    required this.action,
    required this.performedAt,
    required this.utilityName,
    required this.substationName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? 0,
      performedBy: json['performed_by'] ?? '',
      userEmail: json['user_email'] ?? '',
      action: json['action'] ?? '',
      performedAt: json['performed_at'] ?? '',
      utilityName: json['utility_name'] ?? '',
      substationName: json['substation_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'performed_by': performedBy,
      'user_email': userEmail,
      'action': action,
      'performed_at': performedAt,
      'utility_name': utilityName,
      'substation_name': substationName,
    };
  }

  // Helper method to get formatted date
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(performedAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return performedAt; // Return original if parsing fails
    }
  }

  // Helper method to get short action description
  String get shortAction {
    if (action.length > 50) {
      return '${action.substring(0, 50)}...';
    }
    return action;
  }
}