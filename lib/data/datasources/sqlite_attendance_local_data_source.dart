import 'package:sqflite/sqflite.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/today_status.dart';
import '../models/attendance_model.dart';
import 'i_attendance_local_data_source.dart';
import '../../core/database/database_helper.dart';

class SqliteAttendanceLocalDataSource implements IAttendanceLocalDataSource {
  final DatabaseHelper databaseHelper;

  SqliteAttendanceLocalDataSource({required this.databaseHelper});

  @override
  Future<List<AttendanceRecord>> loadRecords() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAttendances,
      orderBy: 'timestamps DESC',
    );

    return maps.map((map) {
      return AttendanceModel(
        id: map['uuid']?.toString() ?? '',
        serverId: map['server_id']?.toString(),
        uuid: map['uuid']?.toString(),
        userId: map['user_id']?.toString() ?? '',
        type: map['type']?.toString() ?? 'checkin',
        timestamp: DateTime.parse(map['timestamps'].toString()),
        latitude: map['latitude']?.toString() ?? '0.0',
        longitude: map['longitude']?.toString() ?? '0.0',
        locationName: map['location_name']?.toString() ?? 'Lokasi Terdaftar',
        syncStatus: map['sync_status'] == 1,
        syncError: map['sync_error']?.toString(),
      );
    }).toList();
  }

  @override
  Future<void> saveRecords(List<AttendanceRecord> records) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final r in records) {
        batch.insert(
          DatabaseHelper.tableAttendances,
          _recordToMap(r),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableAttendances,
      _recordToMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> getPendingRecords() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAttendances,
      where: 'sync_status = ?',
      whereArgs: [0],
      orderBy: 'timestamps ASC',
    );

    return maps.map((map) {
      return AttendanceModel(
        id: map['uuid']?.toString() ?? '',
        serverId: map['server_id']?.toString(),
        uuid: map['uuid']?.toString(),
        userId: map['user_id']?.toString() ?? '',
        type: map['type']?.toString() ?? 'checkin',
        timestamp: DateTime.parse(map['timestamps'].toString()),
        latitude: map['latitude']?.toString() ?? '0.0',
        longitude: map['longitude']?.toString() ?? '0.0',
        locationName: map['location_name']?.toString() ?? 'Lokasi Terdaftar',
        syncStatus: false,
        syncError: map['sync_error']?.toString(),
      );
    }).toList();
  }

  Future<void> markAsSynced(String uuid, {String? serverId}) async {
    final db = await databaseHelper.database;
    final updateData = <String, dynamic>{
      'sync_status': 1,
      'sync_error': null,
    };
    if (serverId != null) {
      updateData['server_id'] = serverId;
    }

    await db.update(
      DatabaseHelper.tableAttendances,
      updateData,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> markAsSkipped(String uuid, String reason) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseHelper.tableAttendances,
      {
        'sync_status': 1,
        'sync_error': reason,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> saveCachedTodayStatus(TodayStatus status, String userId) async {
    final db = await databaseHelper.database;
    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await db.insert(
      DatabaseHelper.tableTodayStatus,
      {
        'user_id': userId,
        'date': todayDate,
        'checked_in': status.checkedIn ? 1 : 0,
        'checked_out': status.checkedOut ? 1 : 0,
        'can_checkin': status.canCheckIn ? 1 : 0,
        'can_checkout': status.canCheckOut ? 1 : 0,
        'checkin_uuid': status.checkIn?.uuid ?? status.checkIn?.id,
        'checkout_uuid': status.checkOut?.uuid ?? status.checkOut?.id,
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TodayStatus?> getCachedTodayStatus(String userId) async {
    final db = await databaseHelper.database;
    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTodayStatus,
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, todayDate],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final map = maps.first;

    AttendanceRecord? checkIn;
    AttendanceRecord? checkOut;

    final checkinUuid = map['checkin_uuid']?.toString();
    final checkoutUuid = map['checkout_uuid']?.toString();

    if (checkinUuid != null && checkinUuid.isNotEmpty) {
      final records = await db.query(
        DatabaseHelper.tableAttendances,
        where: 'uuid = ?',
        whereArgs: [checkinUuid],
        limit: 1,
      );
      if (records.isNotEmpty) {
        checkIn = AttendanceModel.fromJson(records.first);
      }
    }

    if (checkoutUuid != null && checkoutUuid.isNotEmpty) {
      final records = await db.query(
        DatabaseHelper.tableAttendances,
        where: 'uuid = ?',
        whereArgs: [checkoutUuid],
        limit: 1,
      );
      if (records.isNotEmpty) {
        checkOut = AttendanceModel.fromJson(records.first);
      }
    }

    return TodayStatus(
      checkedIn: map['checked_in'] == 1,
      checkedOut: map['checked_out'] == 1,
      canCheckIn: map['can_checkin'] == 1,
      canCheckOut: map['can_checkout'] == 1,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  Future<void> clearAll() async {
    final db = await databaseHelper.database;
    await db.delete(DatabaseHelper.tableAttendances);
    await db.delete(DatabaseHelper.tableTodayStatus);
  }

  Map<String, dynamic> _recordToMap(AttendanceRecord r) {
    return {
      'uuid': r.uuid ?? r.id,
      'server_id': r.serverId,
      'user_id': r.userId,
      'type': r.type,
      'timestamps': r.timestamp.toIso8601String(),
      'latitude': r.latitude,
      'longitude': r.longitude,
      'location_name': r.locationName,
      'sync_status': r.syncStatus ? 1 : 0,
      'sync_error': r.syncError,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
