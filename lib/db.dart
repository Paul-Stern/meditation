import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:meditation/session.dart';

class DatabaseHelper {
  static final _databaseName = "sessions.db";
  static final _databaseVersion = 1;

  // static final DatabaseHelper instance = DatabaseHelper.instance()
  static Database? _database;
  Future<Database> get db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startedAt INTEGER NOT NULL,
        endedAt INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        message TEXT,
        streakdays INTEGER,
    )
    '''); 
  }
  //
  Future<int> insertSession(Session session) async {
    // get database
    Database db = await _database!;
    return await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<Session>> getSessions() async {
    Database db = await _database!;
    final List<Map<String, Object?>> queryResult = await db.query('sessions');
    return queryResult.map((e) => Session.fromMap(e)).toList();
  }
}