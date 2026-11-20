import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/attendance_record.dart';
import '../models/attendance_model.dart';
import 'i_attendance_local_data_source.dart';

class SharedPrefsDataSource implements IAttendanceLocalDataSource {
  static const String _key = 'attendance_records';

  @override
  Future<List<AttendanceRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return <AttendanceRecord>[];

    try {
      final List<dynamic> jsonList = json.decode(data);
      return jsonList
          .map<AttendanceRecord>((j) => AttendanceModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <AttendanceRecord>[];
    }
  }

  @override
  Future<void> saveRecords(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(
      records.map((r) => AttendanceModel.fromEntity(r).toJson()).toList(),
    );
    await prefs.setString(_key, data);
  }

  @override
  Future<void> saveRecord(AttendanceRecord record) async {
    final records = List<AttendanceRecord>.from(await loadRecords());
    final index = records.indexWhere((r) => r.id == record.id || (r.uuid != null && r.uuid == record.uuid));

    if (index != -1) {
      records[index] = record;
    } else {
      records.add(record);
    }

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await saveRecords(records);
  }
}
