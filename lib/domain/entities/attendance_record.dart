class AttendanceRecord {
  final String id;
  final String? serverId;
  final String? uuid;
  final String userId;
  final String type; // 'checkin' | 'checkout'
  final DateTime timestamp;
  final String latitude;
  final String longitude;
  final String locationName;
  final bool syncStatus;
  final String? syncError;

  const AttendanceRecord({
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
    this.syncError,
  });

  AttendanceRecord copyWith({
    String? id,
    String? serverId,
    String? uuid,
    String? userId,
    String? type,
    DateTime? timestamp,
    String? latitude,
    String? longitude,
    String? locationName,
    bool? syncStatus,
    String? syncError,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
    );
  }
}
