import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/attendance_record.dart';
import 'i_attendance_local_data_source.dart';

class SharedPrefsDataSource implements IAttendanceLocalDataSource {
  @override
  Future<List<AttendanceRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('attendance_records');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((j) => AttendanceRecord.fromJson(j)).toList();
  }

  @override
  Future<void> saveRecords(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(records.map((r) => r.toJson()).toList());
    await prefs.setString('attendance_records', data);
  }
}