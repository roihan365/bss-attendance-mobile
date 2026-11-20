import '../repositories/i_attendance_repository.dart';
import '../entities/attendance_record.dart';

class GetAllRecordsUseCase {
  final IAttendanceRepository repository;

  GetAllRecordsUseCase(this.repository);

  Future<List<AttendanceRecord>> call() async {
    return await repository.getAllRecords();
  }
}