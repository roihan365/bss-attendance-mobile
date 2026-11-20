import '../repositories/i_attendance_repository.dart';
import '../entities/attendance_record.dart';

class CheckInUseCase {
  final IAttendanceRepository repository;

  CheckInUseCase(this.repository);

  Future<AttendanceRecord> call(String userId) async {
    return await repository.checkIn(userId);
  }
}