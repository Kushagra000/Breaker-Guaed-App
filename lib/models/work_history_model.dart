// models/work_history_model.dart
class WorkHistoryResponse {
  final List<String> jes;
  final List<SubstationData> substations;
  final List<FeederData> feeders;
  final List<ShutdownData> shutdowns;

  WorkHistoryResponse({
    required this.jes,
    required this.substations,
    required this.feeders,
    required this.shutdowns,
  });

  factory WorkHistoryResponse.fromJson(Map<String, dynamic> json) {
    return WorkHistoryResponse(
      jes: List<String>.from(json['jes'] ?? []),
      substations: (json['substations'] as List<dynamic>? ?? [])
          .map((item) => SubstationData.fromJson(item))
          .toList(),
      feeders: (json['feeders'] as List<dynamic>? ?? [])
          .map((item) => FeederData.fromJson(item))
          .toList(),
      shutdowns: (json['shutdowns'] as List<dynamic>? ?? [])
          .map((item) => ShutdownData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jes': jes,
      'substations': substations.map((item) => item.toJson()).toList(),
      'feeders': feeders.map((item) => item.toJson()).toList(),
      'shutdowns': shutdowns.map((item) => item.toJson()).toList(),
    };
  }
}

class SubstationData {
  final int id;
  final String substationName;

  SubstationData({
    required this.id,
    required this.substationName,
  });

  factory SubstationData.fromJson(Map<String, dynamic> json) {
    return SubstationData(
      id: json['id'] ?? 0,
      substationName: json['substation_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'substation_name': substationName,
    };
  }
}

class FeederData {
  final int feederId;
  final String feederName;
  final int substationId;

  FeederData({
    required this.feederId,
    required this.feederName,
    required this.substationId,
  });

  factory FeederData.fromJson(Map<String, dynamic> json) {
    return FeederData(
      feederId: json['feeder_id'] ?? 0,
      feederName: json['feeder_name'] ?? '',
      substationId: json['substation_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeder_id': feederId,
      'feeder_name': feederName,
      'substation_id': substationId,
    };
  }
}

class ShutdownData {
  final int id;
  final String purpose;
  final String substationNumber;
  final String substationName;
  final int substationId;
  final String feederNumber;
  final String feederName;
  final String sso;
  final String je;
  final int utilityId;
  final List<LinemanInfo> linemen;
  final String startTime;
  final String endTime;
  final String status;

  ShutdownData({
    required this.id,
    required this.purpose,
    required this.substationNumber,
    required this.substationName,
    required this.substationId,
    required this.feederNumber,
    required this.feederName,
    required this.sso,
    required this.je,
    required this.utilityId,
    required this.linemen,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory ShutdownData.fromJson(Map<String, dynamic> json) {
    return ShutdownData(
      id: json['id'] ?? 0,
      purpose: json['purpose'] ?? '',
      substationNumber: json['substation_number'] ?? '',
      substationName: json['substation_name'] ?? '',
      substationId: json['substation_id'] ?? 0,
      feederNumber: json['feeder_number'] ?? '',
      feederName: json['feeder_name'] ?? '',
      sso: json['sso'] ?? '',
      je: json['je'] ?? '',
      utilityId: json['utility_id'] ?? 0,
      linemen: (json['linemen'] as List<dynamic>? ?? [])
          .map((item) => LinemanInfo.fromJson(item))
          .toList(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'substation_number': substationNumber,
      'substation_name': substationName,
      'substation_id': substationId,
      'feeder_number': feederNumber,
      'feeder_name': feederName,
      'sso': sso,
      'je': je,
      'utility_id': utilityId,
      'linemen': linemen.map((item) => item.toJson()).toList(),
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
    };
  }
}

class LinemanInfo {
  final String name;
  final String phone;

  LinemanInfo({
    required this.name,
    required this.phone,
  });

  factory LinemanInfo.fromJson(Map<String, dynamic> json) {
    return LinemanInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}