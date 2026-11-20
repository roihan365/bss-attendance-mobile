import '../repositories/i_attendance_repository.dart';

class SyncAttendanceUseCase {
  final IAttendanceRepository repository;

  SyncAttendanceUseCase(this.repository);

  Future<void> call() async {
    // Asumsikan repository memiliki method syncAllPending
    // Kita perlu tambahkan di interface IAttendanceRepository
    await repository.syncAllPending();
  }
}