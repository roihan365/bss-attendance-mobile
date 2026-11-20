import '../entities/attendance_record.dart';
import '../repositories/i_attendance_repository.dart';

class GetAttendanceHistoryUseCase {
  final IAttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<List<AttendanceRecord>> call({
    DateTime? startDate,
    DateTime? endDate,
    int? month,
    int? year,
    String? type,
    int? page,
    int? perPage,
  }) async {
    return await repository.getAttendanceHistory(
      startDate: startDate,
      endDate: endDate,
      month: month,
      year: year,
      type: type,
      page: page,
      perPage: perPage,
    );
  }
}
