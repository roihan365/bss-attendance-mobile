import '../../domain/repositories/i_attendance_repository.dart'; // reuse LocationData

abstract class ILocationService {
  Future<LocationData> getCurrentLocation();
}