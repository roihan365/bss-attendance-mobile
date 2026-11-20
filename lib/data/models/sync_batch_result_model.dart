import '../../domain/entities/sync_batch_result.dart';
import 'attendance_model.dart';

class SkippedAttendanceModel extends SkippedAttendance {
  const SkippedAttendanceModel({
    required super.uuid,
    required super.type,
    required super.reason,
  });

  factory SkippedAttendanceModel.fromJson(Map<String, dynamic> json) {
    return SkippedAttendanceModel(
      uuid: json['uuid']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? 'Dilewati oleh server',
    );
  }
}

class SyncBatchResultModel extends SyncBatchResult {
  const SyncBatchResultModel({
    required super.totalReceived,
    required super.totalSaved,
    required super.totalSkipped,
    required super.savedRecords,
    required super.skippedRecords,
  });

  factory SyncBatchResultModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawSkipped = json['skipped'];

    final saved = <AttendanceModel>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          saved.add(AttendanceModel.fromServerJson(item));
        }
      }
    }

    final skipped = <SkippedAttendanceModel>[];
    if (rawSkipped is List) {
      for (final item in rawSkipped) {
        if (item is Map<String, dynamic>) {
          skipped.add(SkippedAttendanceModel.fromJson(item));
        }
      }
    }

    return SyncBatchResultModel(
      totalReceived: (json['total_received'] as num?)?.toInt() ?? 0,
      totalSaved: (json['total_saved'] as num?)?.toInt() ?? 0,
      totalSkipped: (json['total_skipped'] as num?)?.toInt() ?? 0,
      savedRecords: saved,
      skippedRecords: skipped,
    );
  }
}
