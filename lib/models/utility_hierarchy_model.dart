// models/utility_hierarchy_model.dart
class UtilityHierarchyResponse {
  final List<UtilityData> utilities;

  UtilityHierarchyResponse({required this.utilities});

  factory UtilityHierarchyResponse.fromJson(Map<String, dynamic> json) {
    return UtilityHierarchyResponse(
      utilities: (json['utilities'] as List)
          .map((utility) => UtilityData.fromJson(utility))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilities': utilities.map((utility) => utility.toJson()).toList(),
    };
  }
}

class UtilityData {
  final int utilityId;
  final String utilityName;
  final List<SubstationData> substations;

  UtilityData({
    required this.utilityId,
    required this.utilityName,
    required this.substations,
  });

  factory UtilityData.fromJson(Map<String, dynamic> json) {
    return UtilityData(
      utilityId: json['utility_id'],
      utilityName: json['utility_name'],
      substations: (json['substations'] as List)
          .map((substation) => SubstationData.fromJson(substation))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utility_id': utilityId,
      'utility_name': utilityName,
      'substations': substations.map((substation) => substation.toJson()).toList(),
    };
  }
}

class SubstationData {
  final int substationId;
  final String substationName;
  final String substationNumber;
  final List<FeederData> feeders;

  SubstationData({
    required this.substationId,
    required this.substationName,
    required this.substationNumber,
    required this.feeders,
  });

  factory SubstationData.fromJson(Map<String, dynamic> json) {
    return SubstationData(
      substationId: json['substation_id'],
      substationName: json['substation_name'],
      substationNumber: json['substation_number'],
      feeders: (json['feeders'] as List)
          .map((feeder) => FeederData.fromJson(feeder))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'substation_id': substationId,
      'substation_name': substationName,
      'substation_number': substationNumber,
      'feeders': feeders.map((feeder) => feeder.toJson()).toList(),
    };
  }
}

class FeederData {
  final int feederId;
  final String feederName;
  final String feederNumber;

  FeederData({
    required this.feederId,
    required this.feederName,
    required this.feederNumber,
  });

  factory FeederData.fromJson(Map<String, dynamic> json) {
    return FeederData(
      feederId: json['feeder_id'],
      feederName: json['feeder_name'],
      feederNumber: json['feeder_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeder_id': feederId,
      'feeder_name': feederName,
      'feeder_number': feederNumber,
    };
  }
}