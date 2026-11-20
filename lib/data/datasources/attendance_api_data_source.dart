import 'dart:convert';

import 'package:bss_attendance_new/domain/entities/attendance_today.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/attendance_record.dart';
import 'i_attendance_remote_data_source.dart';

class AttendanceApiDataSource implements IAttendanceRemoteDataSource {
  final String baseUrl;
  final Future<String?> Function() getToken;

  AttendanceApiDataSource({required this.baseUrl, required this.getToken});

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Mengambil pesan error dari response API.
  ///
  /// Prioritas:
  /// 1. errors jika ada
  /// 2. message jika errors null/kosong
  String _getErrorMessage(Map<String, dynamic> data) {
    final errors = data['errors'];

    if (errors != null) {
      if (errors is Map && errors.isNotEmpty) {
        final messages = <String>[];

        errors.forEach((field, value) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('\n');
      }
    }

    return data['message']?.toString() ?? 'Terjadi kesalahan';
  }

  /// Memastikan response API sukses.
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> data;

    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Response server tidak valid (${response.statusCode})');
    }

    if (response.statusCode == 401) {
      throw Exception(
        data['message']?.toString() ?? 'Sesi kadaluarsa, silakan login ulang',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_getErrorMessage(data));
    }

    if (data['success'] != true) {
      throw Exception(_getErrorMessage(data));
    }

    return data;
  }

  @override
  Future<AttendanceRecord> sendCheckIn(AttendanceRecord record) async {
    return _sendAttendance(record);
  }

  @override
  Future<AttendanceRecord> sendCheckOut(AttendanceRecord record) async {
    return _sendAttendance(record);
  }

  Future<AttendanceRecord> _sendAttendance(AttendanceRecord record) async {
    final headers = await _getHeaders();

    if (headers['Authorization'] == null) {
      throw Exception('Token tidak tersedia, silakan login ulang');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/attendance/save'),
            headers: headers,
            body: json.encode(record.toApiJson()),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _parseResponse(response);

      final serverData = responseData['data'];

      if (serverData == null || serverData is! Map) {
        throw Exception('Data absensi dari server tidak ditemukan');
      }

      return record.copyWith(
        serverId: serverData['id']?.toString(),
        uuid: serverData['uuid']?.toString(),
        userId: serverData['user_id']?.toString() ?? record.userId,
        type: _mapServerType(serverData['type']?.toString() ?? record.type),
        timestamp: serverData['timestamps'] != null
            ? DateTime.parse(serverData['timestamps'].toString())
            : record.timestamp,
        latitude: serverData['latitude'] ?? record.latitude,
        longitude: serverData['longitude'] ?? record.longitude,
        locationName:
            serverData['location_name']?.toString() ?? record.locationName,
        syncStatus: true,
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengirim data ke server: $e');
    }
  }

  String _mapServerType(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
      case 'check_in':
      case 'in':
        return 'check_in';

      case 'checkout':
      case 'check_out':
      case 'out':
        return 'check_out';

      default:
        return type;
    }
  }

  @override
  Future<List<AttendanceRecord>> fetchAllRecords() async {
    final headers = await _getHeaders();

    if (headers['Authorization'] == null) {
      throw Exception('Token tidak tersedia, silakan login ulang');
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/attendance/history'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _parseResponse(response);

      final data = responseData['data'];

      if (data == null) {
        return [];
      }

      if (data is! List) {
        throw Exception('Format data history dari server tidak valid');
      }

      return data.map<AttendanceRecord>((item) {
        return _fromServerJson(item as Map<String, dynamic>);
      }).toList();
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil riwayat absensi: $e');
    }
  }

  @override
  Future<TodayAttendance> fetchTodayAttendance() async {
    final headers = await _getHeaders();

    if (headers['Authorization'] == null) {
      throw Exception('Token tidak tersedia, silakan login ulang');
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/attendance/today'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Response /today bukan object JSON');
      }

      final rawData = responseData['data'];

      if (rawData is! Map) {
        throw Exception('Format data /today tidak valid: data bukan object');
      }

      final data = Map<String, dynamic>.from(rawData);

      return TodayAttendance(
        checkedIn: data['checked_in'] == true,
        checkedOut: data['checked_out'] == true,
        canCheckIn: data['can_checkin'] == true,
        canCheckOut: data['can_checkout'] == true,

        checkIn: data['checkin'] is Map
            ? AttendanceRecord.fromJson(
                Map<String, dynamic>.from(data['checkin']),
              )
            : null,

        checkOut: data['checkout'] is Map
            ? AttendanceRecord.fromJson(
                Map<String, dynamic>.from(data['checkout']),
              )
            : null,
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil status absensi hari ini: $e');
    }
  }

  AttendanceRecord _fromServerJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      serverId: json['id']?.toString(),
      uuid: json['uuid']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      type: _mapServerType(json['type']?.toString() ?? ''),
      timestamp: DateTime.parse(json['timestamps'].toString()),
      latitude: json['latitude'],
      longitude: json['longitude'],
      locationName: json['location_name']?.toString() ?? 'Unknown Location',
      syncStatus: json['sync_status'] == true ? true : false,
    );
  }
}

/// Extension untuk copyWith
extension AttendanceRecordCopyWith on AttendanceRecord {
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
    );
  }
}
