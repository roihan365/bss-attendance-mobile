import 'attendance_record.dart';

class SkippedAttendance {
  final String uuid;
  final String type;
  final String reason;

  const SkippedAttendance({
    required this.uuid,
    required this.type,
    required this.reason,
  });
}

class SyncBatchResult {
  final int totalReceived;
  final int totalSaved;
  final int totalSkipped;
  final List<AttendanceRecord> savedRecords;
  final List<SkippedAttendance> skippedRecords;

  const SyncBatchResult({
    required this.totalReceived,
    required this.totalSaved,
    required this.totalSkipped,
    required this.savedRecords,
    required this.skippedRecords,
  });
}
