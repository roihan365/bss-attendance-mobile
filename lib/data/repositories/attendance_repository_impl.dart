import '../../core/utils/app_logger.dart';
import '../../core/utils/uuid_helper.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/sync_batch_result.dart';
import '../../domain/entities/today_status.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../datasources/connectivity_service.dart';
import '../datasources/i_attendance_local_data_source.dart';
import '../datasources/i_location_service.dart';

class AttendanceRepositoryImpl implements IAttendanceRepository {
  final IAttendanceLocalDataSource localDataSource;
  final ILocationService locationService;
  final IAttendanceRemoteDataSourceNew remoteDataSource;
  final ConnectivityService connectivityService;
  final Future<String?> Function() getUserId;

  AttendanceRecord? _currentCheckIn;
  bool _isCheckedIn = false;

  AttendanceRepositoryImpl({
    required this.localDataSource,
    required this.locationService,
    required this.remoteDataSource,
    required this.connectivityService,
    required this.getUserId,
  });

  @override
  Future<TodayStatus> getTodayStatus() async {
    final hasInternet = await connectivityService.hasInternet();

    if (!hasInternet) {
      return _deriveLocalTodayStatus();
    }

    try {
      final remoteToday = await remoteDataSource.fetchTodayStatus();
      _isCheckedIn = remoteToday.checkedIn && !remoteToday.checkedOut;
      _currentCheckIn = remoteToday.checkIn;
      return remoteToday;
    } catch (_) {
      return _deriveLocalTodayStatus();
    }
  }

  Future<TodayStatus> _deriveLocalTodayStatus() async {
    final records = await getAllRecords();
    final now = DateTime.now();
    final todayRecords = records.where((r) {
      return r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day;
    }).toList();

    AttendanceRecord? checkIn;
    AttendanceRecord? checkOut;

    for (final r in todayRecords) {
      if (r.type == 'checkin' && checkIn == null) {
        checkIn = r;
      } else if (r.type == 'checkout' && checkOut == null) {
        checkOut = r;
      }
    }

    final hasCheckIn = checkIn != null;
    final hasCheckOut = checkOut != null;

    final status = TodayStatus(
      checkedIn: hasCheckIn,
      checkedOut: hasCheckOut,
      canCheckIn: !hasCheckIn,
      canCheckOut: hasCheckIn && !hasCheckOut,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    _isCheckedIn = status.checkedIn && !status.checkedOut;
    _currentCheckIn = status.checkIn;

    return status;
  }

  @override
  Future<AttendanceRecord> checkIn(String userId) async {
    final status = await getTodayStatus();
    if (!status.canCheckIn) {
      throw Exception('Anda sudah melakukan presensi masuk hari ini.');
    }

    final location = await locationService.getCurrentLocation();
    final recordUuid = UuidHelper.generate();

    final record = AttendanceRecord(
      id: recordUuid,
      uuid: recordUuid,
      userId: userId,
      type: 'checkin',
      timestamp: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.locationName,
      syncStatus: false,
    );

    // 1. Simpan selalu ke penyimpanan lokal terlebih dahulu (Offline-First)
    await saveRecord(record);
    AppLogger.i('ATTENDANCE', '💾 Presensi Masuk disimpan ke SQLite lokal (UUID: $recordUuid, Lat: ${location.latitude}, Long: ${location.longitude})');

    // 2. Jika online, langsung kirim ke server secara real-time
    final hasInternet = await connectivityService.hasInternet();
    AppLogger.i('ATTENDANCE', '📡 Memeriksa status koneksi internet: hasInternet=$hasInternet');

    if (hasInternet) {
      try {
        AppLogger.i('ATTENDANCE', '🚀 Mengirim absensi masuk ke server real-time (POST /attendance/save)...');
        final synced = await remoteDataSource.sendAttendance(record);
        AppLogger.i('ATTENDANCE', 'SUKSES terkirim ke server! Server ID: ${synced.serverId}, syncStatus: ${synced.syncStatus}');
        await saveRecord(synced);
        return synced;
      } catch (e, stack) {
        AppLogger.e('ATTENDANCE', '❌ GAGAL mengirim ke API real-time, record tetap tersimpan di SQLite sebagai antrean pending: $e', e, stack);
        final failedRecord = record.copyWith(syncError: e.toString());
        await saveRecord(failedRecord);
      }
    } else {
      AppLogger.w('ATTENDANCE', '⚠️ Perangkat offline. Presensi masuk disimpan sebagai antrean offline.');
    }

    return record;
  }

  @override
  Future<AttendanceRecord> checkOut(String userId) async {
    final status = await getTodayStatus();
    if (!status.canCheckOut) {
      throw Exception('Anda tidak dapat melakukan presensi pulang saat ini.');
    }

    final location = await locationService.getCurrentLocation();
    final recordUuid = UuidHelper.generate();

    final record = AttendanceRecord(
      id: recordUuid,
      uuid: recordUuid,
      userId: userId,
      type: 'checkout',
      timestamp: DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      locationName: location.locationName,
      syncStatus: false,
    );

    await saveRecord(record);
    AppLogger.i('ATTENDANCE', '💾 Presensi Pulang disimpan ke SQLite lokal (UUID: $recordUuid)');

    final hasInternet = await connectivityService.hasInternet();
    AppLogger.i('ATTENDANCE', '📡 Memeriksa status koneksi internet: hasInternet=$hasInternet');

    if (hasInternet) {
      try {
        AppLogger.i('ATTENDANCE', '🚀 Mengirim absensi pulang ke server real-time (POST /attendance/save)...');
        final synced = await remoteDataSource.sendAttendance(record);
        AppLogger.i('ATTENDANCE', 'SUKSES terkirim ke server! Server ID: ${synced.serverId}, syncStatus: ${synced.syncStatus}');
        await saveRecord(synced);
        return synced;
      } catch (e, stack) {
        AppLogger.e('ATTENDANCE', '❌ GAGAL mengirim ke API real-time, record tetap tersimpan di SQLite sebagai antrean pending: $e', e, stack);
        final failedRecord = record.copyWith(syncError: e.toString());
        await saveRecord(failedRecord);
      }
    } else {
      AppLogger.w('ATTENDANCE', '⚠️ Perangkat offline. Presensi pulang disimpan sebagai antrean offline.');
    }

    return record;
  }

  @override
  Future<SyncBatchResult> syncBatchOffline() async {
    final localRecords = await localDataSource.loadRecords();
    final pendingRecords = localRecords.where((r) => !r.syncStatus).toList();

    AppLogger.i('SYNC', '🔄 Memulai proses sinkronisasi antrean offline...');

    if (pendingRecords.isEmpty) {
      AppLogger.i('SYNC', 'Tidak ada antrean offline yang perlu dikirim (pending count: 0).');
      return const SyncBatchResult(
        totalReceived: 0,
        totalSaved: 0,
        totalSkipped: 0,
        savedRecords: [],
        skippedRecords: [],
      );
    }

    AppLogger.i('SYNC', '📦 Ditemukan ${pendingRecords.length} data antrean offline yang belum tersinkron.');

    final hasInternet = await connectivityService.hasInternet();
    if (!hasInternet) {
      AppLogger.w('SYNC', '⚠️ Tidak dapat menyinkronkan: Perangkat sedang offline.');
      throw Exception('Perangkat sedang offline. Sinkronisasi akan berjalan saat online.');
    }

    try {
      AppLogger.i('SYNC', '🚀 Mengirim ${pendingRecords.length} data ke endpoint batch POST /attendance/sync-offline...');
      final result = await remoteDataSource.syncBatchOffline(pendingRecords);
      AppLogger.i('SYNC', 'Respon sync batch diterima: Total diterima=${result.totalReceived}, Berhasil disimpan=${result.totalSaved}, Dilewati=${result.totalSkipped}');

      // Perbarui record di penyimpanan lokal berdasarkan respon server
      final updatedRecords = List<AttendanceRecord>.from(localRecords);

      for (final saved in result.savedRecords) {
        AppLogger.i('SYNC', '  -> Data tersimpan di server: UUID=${saved.uuid}, ID=${saved.serverId}');
        final index = updatedRecords.indexWhere((r) => r.uuid == saved.uuid || r.id == saved.id);
        if (index != -1) {
          updatedRecords[index] = saved.copyWith(syncStatus: true, syncError: null);
        }
      }

      for (final skipped in result.skippedRecords) {
        AppLogger.w('SYNC', '  -> Data dilewati oleh server: UUID=${skipped.uuid}, Alasan: ${skipped.reason}');
        final index = updatedRecords.indexWhere((r) => r.uuid == skipped.uuid);
        if (index != -1) {
          updatedRecords[index] = updatedRecords[index].copyWith(
            syncStatus: true,
            syncError: skipped.reason,
          );
        }
      }

      await localDataSource.saveRecords(updatedRecords);
      _updateCheckInState(updatedRecords);

      return result;
    } catch (e, stack) {
      AppLogger.e('SYNC', '❌ Sinkronisasi batch gagal dieksekusi: $e', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? month,
    int? year,
    String? type,
    int? page,
    int? perPage,
  }) async {
    final hasInternet = await connectivityService.hasInternet();

    if (hasInternet) {
      try {
        final serverRecords = await remoteDataSource.fetchAttendanceHistory(
          startDate: startDate,
          endDate: endDate,
          month: month,
          year: year,
          type: type,
          page: page,
          perPage: perPage,
        );

        // Gabungkan dengan data lokal yang belum tersync
        final localRecords = await localDataSource.loadRecords();
        final pending = localRecords.where((r) => !r.syncStatus).toList();

        final merged = <String, AttendanceRecord>{};
        for (final r in serverRecords) {
          merged[r.id] = r;
        }
        for (final r in pending) {
          merged[r.id] = r;
        }

        final combined = List<AttendanceRecord>.from(merged.values)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return combined;
      } catch (_) {
        // Fallback to local
      }
    }

    return await getAllRecords();
  }

  @override
  Future<List<AttendanceRecord>> getAllRecords() async {
    final localRecords = List<AttendanceRecord>.from(await localDataSource.loadRecords());
    localRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _updateCheckInState(localRecords);
    return localRecords;
  }

  @override
  Future<void> saveRecord(AttendanceRecord record) async {
    await localDataSource.saveRecord(record);
    final records = List<AttendanceRecord>.from(await localDataSource.loadRecords());
    _updateCheckInState(records);
  }

  void _updateCheckInState(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      _isCheckedIn = false;
      _currentCheckIn = null;
      return;
    }

    final sorted = [...records]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    AttendanceRecord? lastCheckIn;

    for (final r in sorted) {
      if (r.type == 'checkin') {
        lastCheckIn = r;
        break;
      }
    }

    if (lastCheckIn == null) {
      _isCheckedIn = false;
      _currentCheckIn = null;
      return;
    }

    final hasCheckOut = sorted.any(
      (r) => r.type == 'checkout' && r.timestamp.isAfter(lastCheckIn!.timestamp),
    );

    _isCheckedIn = !hasCheckOut;
    _currentCheckIn = _isCheckedIn ? lastCheckIn : null;
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    return await locationService.getCurrentLocation();
  }

  @override
  Future<AttendanceRecord?> getCurrentCheckIn() async => _currentCheckIn;

  @override
  Future<bool> isCheckedIn() async => _isCheckedIn;

  @override
  Future<void> clearAll() async {
    await localDataSource.saveRecords([]);
    _isCheckedIn = false;
    _currentCheckIn = null;
  }
}
