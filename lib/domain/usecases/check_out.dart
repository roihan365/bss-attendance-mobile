import '../repositories/i_attendance_repository.dart';
import '../entities/attendance_record.dart';

class CheckOutUseCase {
  final IAttendanceRepository repository;

  CheckOutUseCase(this.repository);

  Future<AttendanceRecord> call(String userId) async {
    return await repository.checkOut(userId);
  }
}