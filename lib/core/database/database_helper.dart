import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'bss_attendance.db';
  static const int _dbVersion = 1;

  static const String tableAttendances = 'attendances';
  static const String tableTodayStatus = 'cached_today_status';

  static Database? _database;
  final Database? customDatabase;

  DatabaseHelper({this.customDatabase});

  Future<Database> get database async {
    if (customDatabase != null) {
      return customDatabase!;
    }
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel Riwayat & Antrean Absensi (Offline Queue + History Cache)
    await db.execute('''
      CREATE TABLE $tableAttendances (
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

    // Index timestamps untuk sorting performan tinggi
    await db.execute('''
      CREATE INDEX idx_attendances_timestamps 
      ON $tableAttendances (timestamps DESC)
    ''');

    // Index sync_status untuk pencarian cepat antrean pending
    await db.execute('''
      CREATE INDEX idx_attendances_sync_status 
      ON $tableAttendances (sync_status)
    ''');

    // 2. Tabel Cache Status Hari Ini (Today Status Cache)
    await db.execute('''
      CREATE TABLE $tableTodayStatus (
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
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
