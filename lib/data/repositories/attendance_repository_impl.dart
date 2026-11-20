import 'package:bss_attendance_new/data/datasources/connectivity_service.dart';
import 'package:bss_attendance_new/data/datasources/i_attendance_remote_data_source.dart';
import 'package:bss_attendance_new/domain/entities/attendance_today.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../datasources/i_attendance_local_data_source.dart';
import '../datasources/i_location_service.dart';

class AttendanceRepositoryImpl implements IAttendanceRepository {
  final IAttendanceLocalDataSource localDataSource;
  final ILocationService locationService;
  final IAttendanceRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final Future<String?> Function() getUserId;

  List<AttendanceRecord>? _cachedRecords;
  AttendanceRecord? _currentCheckIn;
  bool _isCheckedIn = false;
  TodayAttendance? _todayAttendance;

  AttendanceRepositoryImpl({
    required this.localDataSource,
    required this.locationService,
    required this.remoteDataSource,
    required this.connectivityService,
    required this.getUserId,
  });

  Future<TodayAttendance?> _fetchToday() async {
    final hasInternet = await connectivityService.hasInternet();

    if (!hasInternet) {
      return _todayAttendance;
    }

    try {
      final today = await remoteDataSource.fetchTodayAttendance();

      _todayAttendance = today;

      _isCheckedIn = today.checkedIn && !today.checkedOut;
      _currentCheckIn = today.checkIn;

      return today;
    } catch (e) {
      print('Get today attendance gagal: $e');

      return _todayAttendance;
    }
  }

  Future<void> _loadAndCache() async {
    final records = await localDataSource.loadRecords();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _cachedRecords = records;

    _updateCheckInState(records);
  }

  void _updateCheckInState(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      _isCheckedIn = false;
      _currentCheckIn = null;
      return;
    }

    final sortedRecords = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    AttendanceRecord? lastCheckIn;

    for (final record in sortedRecords) {
      if (record.type == 'checkin') {
        lastCheckIn = record;
        break;
      }
    }

    if (lastCheckIn == null) {
      _isCheckedIn = false;
      _currentCheckIn = null;
      return;
    }

    final hasCheckOut = sortedRecords.any(
      (record) =>
          record.type == 'check_out' &&
          record.timestamp.isAfter(lastCheckIn!.timestamp),
    );

    if (!hasCheckOut) {
      _isCheckedIn = true;
      _currentCheckIn = lastCheckIn;
    } else {
      _isCheckedIn = false;
      _currentCheckIn = null;
    }
  }

  /// Mengambil data attendance.
  ///
  /// Behavior:
  /// - Offline:
  ///   menggunakan data lokal.
  ///
  /// - Online:
  ///   server menjadi source of truth untuk record yang sudah tersync.
  ///   Record lokal yang masih pending tetap dipertahankan.
  ///
  /// Hasil akhirnya:
  ///     server records + pending local records
  @override
  Future<List<AttendanceRecord>> getAllRecords() async {
    if (_cachedRecords == null) {
      await _loadAndCache();
    }

    final localRecords = await localDataSource.loadRecords();

    // Pastikan cache mengikuti local storage.
    _cachedRecords = [...localRecords]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _updateCheckInState(_cachedRecords!);

    final hasInternet = await connectivityService.hasInternet();

    if (!hasInternet) {
      return _cachedRecords!;
    }

    try {
      final remoteRecords = await remoteDataSource.fetchAllRecords();

      /*
       * Server adalah source of truth.
       *
       * Hanya record pending dari local yang dipertahankan.
       * Semua record yang sudah sync akan mengikuti data server.
       */
      final pendingLocalRecords = localRecords
          .where((record) => record.syncStatus == false)
          .toList();

      /*
       * Gunakan Map berdasarkan ID untuk menghindari duplicate.
       *
       * Server dimasukkan terlebih dahulu.
       * Pending local kemudian ditambahkan.
       */
      final merged = <String, AttendanceRecord>{};

      for (final record in remoteRecords) {
        merged[record.id] = record;
      }

      for (final record in pendingLocalRecords) {
        merged[record.id] = record;
      }

      final records = merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      /*
       * Local storage sekarang merepresentasikan:
       *
       *   server records
       *   +
       *   pending local records
       */
      await localDataSource.saveRecords(records);

      _cachedRecords = records;

      _updateCheckInState(records);

      return _cachedRecords!;
    } catch (e) {
      /*
       * Jika API /history gagal:
       * jangan menghapus local data.
       *
       * Local masih bisa digunakan sebagai fallback.
       */
      throw Exception(e);
      // print('Get attendance history gagal: $e');

      return _cachedRecords!;
    }
  }

  @override
  Future<void> saveRecord(AttendanceRecord record) async {
    if (_cachedRecords == null) {
      await _loadAndCache();
    }

    final records = [...?_cachedRecords];

    /*
     * Hindari duplicate ID.
     */
    final existingIndex = records.indexWhere((item) => item.id == record.id);

    if (existingIndex != -1) {
      records[existingIndex] = record;
    } else {
      records.insert(0, record);
    }

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    await localDataSource.saveRecords(records);

    _cachedRecords = records;

    _updateCheckInState(records);
  }

  @override
  Future<AttendanceRecord?> getCurrentCheckIn() async {
    await getAllRecords();

    return _currentCheckIn;
  }

  @override
  Future<bool> isCheckedIn() async {
    final today = await _fetchToday();

    if (today != null) {
      return today.checkedIn && !today.checkedOut;
    }

    // Fallback kalau offline dan belum punya /today cache.
    await getAllRecords();

    return _isCheckedIn;
  }

  Future<bool> canCheckIn() async {
    final today = await _fetchToday();

    if (today != null) {
      return today.canCheckIn;
    }

    return false;
  }

  Future<bool> canCheckOut() async {
    final today = await _fetchToday();

    if (today != null) {
      return today.canCheckOut;
    }

    return false;
  }

  @override
  Future<void> clearAll() async {
    await localDataSource.saveRecords([]);

    _cachedRecords = [];
    _isCheckedIn = false;
    _currentCheckIn = null;
  }

  @override
  Future<AttendanceRecord> checkIn(String userId) async {
    final today = await _fetchToday();

    if (today != null && !today.canCheckIn) {
      throw Exception('Anda tidak dapat melakukan check-in hari ini.');
    }

    final location = await locationService.getCurrentLocation();

    final record = AttendanceRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
      userId: userId,
      type: 'checkin',
      timestamp: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.locationName,
      syncStatus: false,
    );

    /*
     * Simpan lokal terlebih dahulu.
     *
     * Record ini akan dianggap pending sampai
     * berhasil dikirim ke server.
     */
    await saveRecord(record);

    /*
     * Jangan await supaya tetap offline-first.
     */
    _syncRecord(record);

    return record;
  }

  @override
  Future<AttendanceRecord> checkOut(String userId) async {
    final today = await _fetchToday();
    print(today);

    if (today != null && !today.canCheckOut) {
      throw Exception('Anda tidak dapat melakukan check-out hari ini.');
    }

    final location = await locationService.getCurrentLocation();

    final record = AttendanceRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
      userId: userId,
      type: 'check_out',
      timestamp: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.locationName,
      syncStatus: false,
    );

    await saveRecord(record);

    _syncRecord(record);

    return record;
  }

  Future<void> _syncRecord(AttendanceRecord record) async {
    try {
      final hasInternet = await connectivityService.hasInternet();

      if (!hasInternet) {
        return;
      }

      AttendanceRecord syncedRecord;

      if (record.type == 'checkin') {
        syncedRecord = await remoteDataSource.sendCheckIn(record);
      } else if (record.type == 'check_out') {
        syncedRecord = await remoteDataSource.sendCheckOut(record);
      } else {
        throw Exception('Tipe attendance tidak dikenal: ${record.type}');
      }

      /*
       * Jangan panggil getAllRecords() di sini.
       *
       * getAllRecords() melakukan GET /history.
       * Setelah send berhasil, kita cukup mengganti
       * pending record dengan response dari API.
       */
      getAllRecords();
      if (_cachedRecords == null) {
        await _loadAndCache();
      }

      final records = [...?_cachedRecords];

      final index = records.indexWhere((item) => item.id == record.id);

      if (index != -1) {
        records[index] = syncedRecord;
      } else {
        /*
         * Jika record belum ada di cache,
         * masukkan response server.
         */
        records.add(syncedRecord);
      }

      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      await localDataSource.saveRecords(records);

      _cachedRecords = records;

      _updateCheckInState(records);
    } catch (e) {
      /*
       * Jangan hapus record.
       *
       * Record tetap syncStatus == false sehingga
       * syncAllPending() dapat mencobanya kembali.
       */
      throw Exception(e);
      // print('Sync attendance gagal: $e');
    }
  }

  @override
  Future<void> syncAllPending() async {
    /*
     * Baca langsung local storage.
     *
     * Jangan menggunakan getAllRecords() di sini karena
     * getAllRecords() melakukan GET /history dan dapat
     * mengganti data local dengan server.
     */
    final localRecords = await localDataSource.loadRecords();

    final pending = localRecords
        .where((record) => record.syncStatus == false)
        .toList();

    if (pending.isEmpty) {
      /*
       * Tetap refresh server supaya local
       * mendapatkan history terbaru.
       */
      await getAllRecords();
      return;
    }

    final hasInternet = await connectivityService.hasInternet();

    if (!hasInternet) {
      throw Exception('Anda sedang offline!');
    }

    /*
     * Sync satu per satu secara berurutan.
     */
    for (final record in pending) {
      await _syncRecord(record);
    }

    /*
     * Setelah seluruh pending selesai dicoba,
     * lakukan GET /history satu kali.
     *
     * Pada titik ini server menjadi source of truth.
     */
    await getAllRecords();
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    return await locationService.getCurrentLocation();
  }
}
