import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:meditation/session.dart';
import 'package:meditation/utils.dart';

class DatabaseHelper {

static final DatabaseHelper instance = DatabaseHelper._instance();
  static final _databaseName = "sessions.db";
  static final _databaseVersion = 1;


  DatabaseHelper._instance();
  // static final DatabaseHelper instance = DatabaseHelper.instance()
  static Database? _database;
  Future<Database> get db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // create instance

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    log.d("creating database");
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started INTEGER NOT NULL,
        ended INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        message TEXT,
        streakdays INTEGER
    )
    '''); 
  }
  //
  Future<int> insertSession(Session session) async {
    // get database
    Database db = await instance.db;
    log.d("inserting session $session");
    return await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<Session>> getSessions() async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query('sessions');
    return queryResult.map((e) => Session.fromMap(e)).toList();
  }
  // get last id
  Future<int> getLastId() async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query('sessions', orderBy: 'id DESC', limit: 1);
    return queryResult.first['id'] as int;
  }
  // get new id
  Future<int> getNewId() async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query('sessions', orderBy: 'id DESC', limit: 1);
    if (queryResult.isEmpty) {
      return 0;
    } else {
      return (queryResult.first['id'] as int) + 1;
    }
    // if (id == null) {
    //   return 0;
    // } else {
    //   return id;
    // }
  }
}