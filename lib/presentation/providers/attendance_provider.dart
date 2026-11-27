import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/geofence_helper.dart';
import '../../data/datasources/connectivity_service.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/sync_batch_result.dart';
import '../../domain/entities/today_status.dart';
import '../../domain/entities/work_location.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../../domain/usecases/check_in.dart';
import '../../domain/usecases/check_out.dart';
import '../../domain/usecases/get_attendance_history.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_today_status.dart';
import '../../domain/usecases/sync_batch_offline.dart';
import 'auth_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetTodayStatusUseCase getTodayStatusUseCase;
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final SyncBatchOfflineUseCase syncBatchOfflineUseCase;
  final ConnectivityService connectivityService;
  AuthProvider? authProvider;

  List<AttendanceRecord> _records = [];
  TodayStatus _todayStatus = TodayStatus.empty();
  bool _isLoading = false;
  bool _isSyncing = false;
  LocationData? _currentLocation;

  List<AttendanceRecord> get records => _records;
  TodayStatus get todayStatus => _todayStatus;
  bool get isCheckedIn => _todayStatus.checkedIn && !_todayStatus.checkedOut;
  bool get isCheckedOut => _todayStatus.checkedOut;
  bool get canCheckIn => _todayStatus.canCheckIn;
  bool get canCheckOut => _todayStatus.canCheckOut;
  AttendanceRecord? get currentCheckIn => _todayStatus.checkIn;
  AttendanceRecord? get currentCheckOut => _todayStatus.checkOut;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String get currentLocationName => _currentLocation?.locationName ?? 'Mendeteksi lokasi GPS...';
  String? get currentLatitude => _currentLocation?.latitude;
  String? get currentLongitude => _currentLocation?.longitude;
  double? get currentAccuracy => _currentLocation?.accuracy;
  bool get isCurrentMocked => _currentLocation?.isMocked ?? false;

  bool get effectiveIsFlexibleLocation =>
      _todayStatus.isFlexibleLocation || (authProvider?.currentUser?.isFlexibleLocation ?? false);

  List<WorkLocation> get effectiveWorkLocations => _todayStatus.workLocations.isNotEmpty
      ? _todayStatus.workLocations
      : (authProvider?.currentUser?.workLocations ?? const []);

  GeofenceEvaluation? get geofenceEvaluation {
    if (_currentLocation == null) return null;
    final lat = double.tryParse(_currentLocation!.latitude);
    final lng = double.tryParse(_currentLocation!.longitude);
    if (lat == null || lng == null) return null;

    return GeofenceHelper.evaluate(
      latitude: lat,
      longitude: lng,
      isFlexibleLocation: effectiveIsFlexibleLocation,
      workLocations: effectiveWorkLocations,
    );
  }

  bool get isWithinWorkRadius => geofenceEvaluation?.isWithinRadius ?? true;

  int get pendingSyncCount => _records.where((r) => !r.syncStatus).length;

  List<AttendanceRecord> get todayRecords {
    final now = DateTime.now();
    return _records.where((r) {
      return r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  AttendanceProvider({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getTodayStatusUseCase,
    required this.getAttendanceHistoryUseCase,
    required this.getCurrentLocationUseCase,
    required this.syncBatchOfflineUseCase,
    required this.connectivityService,
    this.authProvider,
  }) {
    _loadInitialData();
    _listenConnectivity();
  }

  void updateAuth(AuthProvider? newAuthProvider) {
    authProvider = newAuthProvider;
    if (authProvider != null && authProvider!.isLoggedIn) {
      _loadInitialData();
    }
  }

  void _listenConnectivity() {
    connectivityService.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && pendingSyncCount > 0) {
        syncPending();
      }
    });
  }

  Future<SyncBatchResult?> syncPending() async {
    if (_isSyncing) return null;
    _isSyncing = true;
    notifyListeners();

    try {
      AppLogger.i('PROVIDER', '🔄 Tombol kirim antrean ditekan. Memulai sinkronisasi offline...');
      final result = await syncBatchOfflineUseCase();
      await _loadInitialData();
      AppLogger.i('PROVIDER', 'Sinkronisasi selesai: ${result.totalSaved} tersimpan, ${result.totalSkipped} dilewati.');
      return result;
    } catch (e, stack) {
      AppLogger.e('PROVIDER', '❌ Gagal sinkronisasi antrean: $e', e, stack);
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayStatus = await getTodayStatusUseCase();
      _records = await getAttendanceHistoryUseCase();
      _currentLocation = await getCurrentLocationUseCase();
    } catch (_) {
      // Handled gracefully
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceRecord> checkIn() async {
    if (authProvider == null || !authProvider!.isLoggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = authProvider!.currentUser!.id;
      final record = await checkInUseCase(userId);
      _todayStatus = await getTodayStatusUseCase();
      _records = await getAttendanceHistoryUseCase();
      _currentLocation = await getCurrentLocationUseCase();
      return record;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceRecord> checkOut() async {
    if (authProvider == null || !authProvider!.isLoggedIn) {
      throw Exception('Silakan login terlebih dahulu');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = authProvider!.currentUser!.id;
      final record = await checkOutUseCase(userId);
      _todayStatus = await getTodayStatusUseCase();
      _records = await getAttendanceHistoryUseCase();
      _currentLocation = await getCurrentLocationUseCase();
      return record;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    try {
      _todayStatus = await getTodayStatusUseCase();
      _records = await getAttendanceHistoryUseCase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
