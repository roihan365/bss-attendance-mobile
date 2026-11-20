import '../repositories/i_attendance_repository.dart';
import '../entities/attendance_record.dart';

class GetTodayRecordsUseCase {
  final IAttendanceRepository repository;

  GetTodayRecordsUseCase(this.repository);

  Future<List<AttendanceRecord>> call() async {
    final all = await repository.getAllRecords();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all
        .where((r) =>
            r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}