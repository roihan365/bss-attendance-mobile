import '../repositories/i_attendance_repository.dart';

class GetCurrentLocationUseCase {
  final IAttendanceRepository repository;

  GetCurrentLocationUseCase(this.repository);

  Future<LocationData> call() async {
    return await repository.getCurrentLocation();
  }
}