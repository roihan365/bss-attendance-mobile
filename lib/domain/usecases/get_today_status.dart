import '../entities/today_status.dart';
import '../repositories/i_attendance_repository.dart';

class GetTodayStatusUseCase {
  final IAttendanceRepository repository;

  GetTodayStatusUseCase(this.repository);

  Future<TodayStatus> call() async {
    return await repository.getTodayStatus();
  }
}
