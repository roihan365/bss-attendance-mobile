import 'package:intl/intl.dart';
import '../../core/utils/uuid_helper.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceModel extends AttendanceRecord {
  const AttendanceModel({
    required super.id,
    super.serverId,
    super.uuid,
    required super.userId,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    super.locationName = 'Unknown Location',
    super.workLocationId,
    super.distanceMeters,
    super.isOutOfRange = false,
    super.syncStatus = false,
    super.syncError,
  });

  factory AttendanceModel.fromEntity(AttendanceRecord record) {
    return AttendanceModel(
      id: record.id,
      serverId: record.serverId,
      uuid: record.uuid,
      userId: record.userId,
      type: record.type,
      timestamp: record.timestamp,
      latitude: record.latitude,
      longitude: record.longitude,
      locationName: record.locationName,
      workLocationId: record.workLocationId,
      distanceMeters: record.distanceMeters,
      isOutOfRange: record.isOutOfRange,
      syncStatus: record.syncStatus,
      syncError: record.syncError,
    );
  }

  /// Parsing respons dari database / server API
  factory AttendanceModel.fromServerJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase() ?? 'checkin';
    final normalizedType = (rawType == 'checkout' || rawType == 'check_out' || rawType == 'out')
        ? 'checkout'
        : 'checkin';

    return AttendanceModel(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      serverId: json['id']?.toString(),
      uuid: json['uuid']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      type: normalizedType,
      timestamp: _parseDateTime(json['timestamps']),
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      locationName: json['location_name']?.toString() ?? 'Lokasi Terdaftar',
      workLocationId: int.tryParse(json['work_location_id']?.toString() ?? ''),
      distanceMeters: int.tryParse(json['distance_meters']?.toString() ?? ''),
      isOutOfRange: json['is_out_of_range'] == true || json['is_out_of_range'] == 1,
      syncStatus: json['sync_status'] == null
          ? true
          : (json['sync_status'] == true || json['sync_status'] == 1),
    );
  }

  /// Parsing dari local storage (SharedPreferences / SQLite)
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      serverId: json['serverId']?.toString(),
      uuid: json['uuid']?.toString(),
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'checkin',
      timestamp: _parseDateTime(json['timestamp'] ?? json['timestamps']),
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      locationName: json['locationName']?.toString() ?? json['location_name']?.toString() ?? 'Unknown Location',
      syncStatus: json['syncStatus'] == true || json['sync_status'] == 1 || json['sync_status'] == true,
      syncError: json['syncError']?.toString(),
    );
  }

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
        'syncError': syncError,
      };

  /// Format pengiriman ke endpoint real-time /attendance/save
  Map<String, dynamic> toApiSaveJson() {
    final payload = <String, dynamic>{
      'type': type == 'checkout' ? 'checkout' : 'checkin',
      'timestamps': DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
      'latitude': double.tryParse(latitude) ?? 0.0,
      'longitude': double.tryParse(longitude) ?? 0.0,
      'location_name': locationName,
    };
    final recordUuid = uuid ?? id;
    if (recordUuid.isNotEmpty && UuidHelper.isValid(recordUuid)) {
      payload['uuid'] = recordUuid;
    }
    return payload;
  }

  /// Format pengiriman ke endpoint batch /attendance/sync-offline
  Map<String, dynamic> toApiSyncJson() {
    final recordUuid = (uuid != null && uuid!.isNotEmpty && UuidHelper.isValid(uuid!))
        ? uuid!
        : (UuidHelper.isValid(id) ? id : UuidHelper.generate());
    return {
      'uuid': recordUuid,
      'type': type == 'checkout' ? 'checkout' : 'checkin',
      'timestamps': DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
      'latitude': double.tryParse(latitude) ?? 0.0,
      'longitude': double.tryParse(longitude) ?? 0.0,
      'location_name': locationName,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(str.replaceFirst(' ', 'T'));
    } catch (_) {
      return DateTime.now();
    }
  }
}
