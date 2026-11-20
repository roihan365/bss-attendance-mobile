import '../entities/sync_batch_result.dart';
import '../repositories/i_attendance_repository.dart';

class SyncAttendanceUseCase {
  final IAttendanceRepository repository;

  SyncAttendanceUseCase(this.repository);

  Future<SyncBatchResult> call() async {
    return await repository.syncBatchOffline();
  }
}
