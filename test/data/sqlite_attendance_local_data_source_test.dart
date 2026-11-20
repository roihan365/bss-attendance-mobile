import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bss_attendance_new/core/database/database_helper.dart';
import 'package:bss_attendance_new/data/datasources/sqlite_attendance_local_data_source.dart';
import 'package:bss_attendance_new/domain/entities/attendance_record.dart';
import 'package:bss_attendance_new/domain/entities/today_status.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;
  late SqliteAttendanceLocalDataSource dataSource;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    dbHelper = DatabaseHelper(customDatabase: db);

    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableAttendances} (
        uuid TEXT PRIMARY KEY,
        server_id TEXT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamps TEXT NOT NULL,
        latitude TEXT NOT NULL,
        longitude TEXT NOT NULL,
        location_name TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        sync_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableTodayStatus} (
        user_id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        checked_in INTEGER NOT NULL,
        checked_out INTEGER NOT NULL,
        can_checkin INTEGER NOT NULL,
        can_checkout INTEGER NOT NULL,
        checkin_uuid TEXT,
        checkout_uuid TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    dataSource = SqliteAttendanceLocalDataSource(databaseHelper: dbHelper);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqliteAttendanceLocalDataSource Offline-First Tests', () {
    test('saveRecord and loadRecords persist and retrieve data properly', () async {
      final record = AttendanceRecord(
        id: 'uuid-1',
        uuid: 'uuid-1',
        userId: 'user-1',
        type: 'checkin',
        timestamp: DateTime.parse('2026-11-20T08:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS - Sektor Utara',
        syncStatus: false,
      );

      await dataSource.saveRecord(record);
      final records = await dataSource.loadRecords();

      expect(records.length, 1);
      expect(records.first.uuid, 'uuid-1');
      expect(records.first.type, 'checkin');
      expect(records.first.locationName, 'Site Proyek BSS - Sektor Utara');
      expect(records.first.syncStatus, isFalse);
    });

    test('getPendingRecords returns only records with syncStatus = false', () async {
      final record1 = AttendanceRecord(
        id: 'uuid-1',
        uuid: 'uuid-1',
        userId: 'user-1',
        type: 'checkin',
        timestamp: DateTime.parse('2026-11-19T08:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS',
        syncStatus: true,
      );

      final record2 = AttendanceRecord(
        id: 'uuid-2',
        uuid: 'uuid-2',
        userId: 'user-1',
        type: 'checkout',
        timestamp: DateTime.parse('2026-11-19T17:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS',
        syncStatus: false,
      );

      await dataSource.saveRecords([record1, record2]);

      final pending = await dataSource.getPendingRecords();
      expect(pending.length, 1);
      expect(pending.first.uuid, 'uuid-2');
      expect(pending.first.syncStatus, isFalse);
    });

    test('markAsSynced updates record to sync_status = 1 with server_id', () async {
      final record = AttendanceRecord(
        id: 'uuid-offline-99',
        uuid: 'uuid-offline-99',
        userId: 'user-1',
        type: 'checkin',
        timestamp: DateTime.parse('2026-11-20T08:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS',
        syncStatus: false,
      );

      await dataSource.saveRecord(record);
      await dataSource.markAsSynced('uuid-offline-99', serverId: 'server-id-888');

      final records = await dataSource.loadRecords();
      expect(records.first.syncStatus, isTrue);
      expect(records.first.serverId, 'server-id-888');
    });

    test('markAsSkipped marks record as synced and sets sync_error reason', () async {
      final record = AttendanceRecord(
        id: 'uuid-dup-1',
        uuid: 'uuid-dup-1',
        userId: 'user-1',
        type: 'checkin',
        timestamp: DateTime.parse('2026-11-20T08:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS',
        syncStatus: false,
      );

      await dataSource.saveRecord(record);
      await dataSource.markAsSkipped('uuid-dup-1', 'UUID sudah terdaftar.');

      final records = await dataSource.loadRecords();
      expect(records.first.syncStatus, isTrue);
      expect(records.first.syncError, 'UUID sudah terdaftar.');
    });

    test('saveCachedTodayStatus and getCachedTodayStatus work correctly for user', () async {
      const todayStatus = TodayStatus(
        checkedIn: true,
        checkedOut: false,
        canCheckIn: false,
        canCheckOut: true,
      );

      await dataSource.saveCachedTodayStatus(todayStatus, 'user-1');
      final cached = await dataSource.getCachedTodayStatus('user-1');

      expect(cached, isNotNull);
      expect(cached!.checkedIn, isTrue);
      expect(cached.checkedOut, isFalse);
      expect(cached.canCheckIn, isFalse);
      expect(cached.canCheckOut, isTrue);
    });
  });
}
