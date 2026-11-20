import 'package:bss_attendance_new/data/datasources/connectivity_service.dart';
import 'package:bss_attendance_new/domain/usecases/sync_attendance.dart';
import 'package:bss_attendance_new/presentation/providers/auth_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/check_in.dart';
import '../../domain/usecases/check_out.dart';
import '../../domain/usecases/get_today_records.dart';
import '../../domain/usecases/get_all_records.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/repositories/i_attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetTodayRecordsUseCase getTodayRecordsUseCase;
  final GetAllRecordsUseCase getAllRecordsUseCase;
  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final SyncAttendanceUseCase syncAttendanceUseCase;
  final ConnectivityService connectivityService;
  final AuthProvider? authProvider;

  List<AttendanceRecord> _records = [];
  bool _isCheckedIn = false;
  AttendanceRecord? _currentCheckIn;
  bool _isLoading = false;
  LocationData? _currentLocation;

  List<AttendanceRecord> get records => _records;
  bool get isCheckedIn => _isCheckedIn;
  AttendanceRecord? get currentCheckIn => _currentCheckIn;
  bool get isLoading => _isLoading;
  String get currentLocationName =>
      _currentLocation?.locationName ?? 'Fetching location...';
  String? get currentLatitude => _currentLocation?.latitude;
  String? get currentLongitude => _currentLocation?.longitude;

  List<AttendanceRecord> get todayRecords {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _records
        .where(
          (r) =>
              r.timestamp.year == today.year &&
              r.timestamp.month == today.month &&
              r.timestamp.day == today.day,
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  AttendanceProvider({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getTodayRecordsUseCase,
    required this.getAllRecordsUseCase,
    required this.getCurrentLocationUseCase,
    required this.syncAttendanceUseCase,
    required this.connectivityService,
    this.authProvider,
  }) {
    _loadInitialData();
    _listenConnectivity();
  }

  void _listenConnectivity() {
    connectivityService.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if any connection is active
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      print(hasConnection);
      if (hasConnection) {
        // Internet tersambung, sync pending records
        syncPending();
      }
    });
  }

  Future<void> syncPending() async {
    try {
      await syncAttendanceUseCase();
      // Refresh data setelah sync
      await _loadInitialData();
    } catch (e) {
      // handle error
    }
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await getAllRecordsUseCase();
      _isCheckedIn = await checkInUseCase.repository.isCheckedIn();
      _currentCheckIn = await checkInUseCase.repository.getCurrentCheckIn();
      _currentLocation = await getCurrentLocationUseCase();
    } catch (e) {
      // handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIn() async {
    if (_isCheckedIn) throw Exception('Already checked in');

    if (authProvider == null || !authProvider!.isLoggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = authProvider!.currentUser!.id;
      final record = await checkInUseCase(userId);
      _isCheckedIn = true;
      _currentCheckIn = record;
      _currentLocation = await getCurrentLocationUseCase();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkOut() async {
    if (!_isCheckedIn) throw Exception('Not checked in');
    if (authProvider == null || !authProvider!.isLoggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = authProvider!.currentUser!.id;
      await checkOutUseCase(userId);
      _isCheckedIn = false;
      _currentCheckIn = null;
      _currentLocation = await getCurrentLocationUseCase();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    try {
      _currentLocation = await getCurrentLocationUseCase();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();
    _records = await getAllRecordsUseCase();
    _isCheckedIn = await checkInUseCase.repository.isCheckedIn();
    _currentCheckIn = await checkInUseCase.repository.getCurrentCheckIn();
    _isLoading = false;
    notifyListeners();
  }
}
