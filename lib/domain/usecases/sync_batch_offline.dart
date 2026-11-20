import '../entities/sync_batch_result.dart';
import '../repositories/i_attendance_repository.dart';

class SyncBatchOfflineUseCase {
  final IAttendanceRepository repository;

  SyncBatchOfflineUseCase(this.repository);

  Future<SyncBatchResult> call() async {
    return await repository.syncBatchOffline();
  }
}
