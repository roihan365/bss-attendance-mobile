class AttendanceRecord {
  final String id; // ID lokal
  final String? serverId; // ID database server
  final String? uuid; // UUID dari server
  final String userId;
  final String type; // check_in / check_out
  final DateTime timestamp;
  final String latitude;
  final String longitude;
  final String locationName;
  final bool syncStatus; // true / /false

  AttendanceRecord({
    required this.id,
    this.serverId,
    this.uuid,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.locationName = 'Unknown Location',
    this.syncStatus = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'serverId': serverId,
    'uuid': uuid,
    'userId': userId,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'syncStatus': syncStatus,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      serverId: json['serverId']?.toString(),
      uuid: json['uuid']?.toString(),
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      timestamp: _parseTimestamp(json['timestamps']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationName: json['locationName']?.toString() ?? 'Unknown Location',
      syncStatus: _parseBool(json['sync_status']),
    );
  }

  /// Request ke API Laravel
  Map<String, dynamic> toApiJson() {
    return {
      'type': type == 'checkin' ? 'checkin' : 'checkout',
      'timestamps': timestamp.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      throw const FormatException('Timestamp tidak tersedia');
    }

    if (value is DateTime) {
      return value;
    }

    final valueString = value.toString().trim();

    if (valueString.isEmpty) {
      throw const FormatException('Timestamp kosong');
    }

    // API: 2026-08-13 04:07:00
    return DateTime.parse(valueString.replaceFirst(' ', 'T'));
  }

  static bool _parseBool(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }
}
