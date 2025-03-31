import 'dart:io';
import 'dart:typed_data';

import 'dart:convert' show utf8;

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'package:meditation/session.dart';
import 'package:meditation/utils.dart' as u;

class DatabaseHelper {

static final DatabaseHelper instance = DatabaseHelper._instance();
  static final _databaseName = "sessions.db";
  static final _databaseVersion = 2;


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
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    u.log.d("creating database");
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started INTEGER NOT NULL,
        ended INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        message TEXT
    )
    '''); 
  }
  //
  Future<int> insertSession(Session session) async {
    // get database
    Database db = await instance.db;
    u.log.d("inserting session $session");
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

  Future<List<Session>> getSessionsDesc() async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query('sessions', orderBy: 'started DESC');
    return queryResult.map((e) => Session.fromMap(e)).toList();
  }

  Future<Duration> getTotalDuration() async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query(
      'sessions',
      columns: ['duration'],
      );
    int totalDuration = 0;
    for (var element in queryResult) {
      totalDuration += element['duration'] as int;
    }
    return Duration(milliseconds: totalDuration);
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
  // import sessions from csv
  Future<void> importSessionsFromCsv(String filepath) async {
    Database db = await instance.db;
    final _rawData = await File(filepath).readAsString();
    // log.d("raw data: $_rawData");
    List<List<dynamic>> _csvData = const CsvToListConverter(
      eol: "\n"
    ).convert(_rawData);
    // log.d("csv data: $_csvData");

    // range over the csv data
    for (int i = 1; i < _csvData.length; i++) {
      var row = _csvData[i];
      // log.d('i: $i');
      u.log.d("csv row: $row");
      Session session = Session.fromCsv(row);
      u.log.d("inserting session $session");
      await insertSession(session);
    }
 }
 Future<void> exportSessionsToCsv(String filepath) async {
    Database db = await instance.db;
    final List<Map<String, Object?>> queryResult = await db.query('sessions');
    final List<List<dynamic>> csvData = queryResult.map((e) =>
    [
      e['id'],
      e['duration'],
      e['started'] as String ,
      e['ended'],
      e['message']
      ]
    ).toList();
    final String csv = const ListToCsvConverter().convert(csvData);
    u.log.d('csv: $csv');
    await File(filepath).writeAsString(csv);
 }
 // exportSessionsToU8intList
  Future <Uint8List> exportSessionsToU8intList() async {
    Database db = await instance.db;
    final List<Session> sessions = await getSessions();
    final List<List<dynamic>> csvData = [['id', 'duration', 'started', 'ended', 'message']];
    final List<List<dynamic>> sesData = sessions.map((e) =>
    [
      e.id,
      formatDuration(e.duration),
      e.started.toUtc(),
      e.ended.toUtc(),
      e.message
      ]
    ).toList();
    csvData.addAll(sesData);
    u.log.d('csvData: $csvData');
    final String csv = const ListToCsvConverter(eol: "\n").convert(csvData);
    u.log.d('csv: $csv');
    return utf8.encode(csv);
  }
  Future <int> getStreakDays() async {
    Database db = await instance.db;
    int streakdays = 0;
    DateTime current = DateTime.now();
    int day = current.day;
    final sessions = await getSessionsDesc();
    if (sessions.isEmpty) {
      return 0;
    }
    // final = sessions.map((e) => e.DateTimeToString(e.started)).toSet();
    for (var s in sessions) {
      u.log.d("session started: ${s.started}\nnow: $current\nstreakdays: $streakdays");
      if (current.difference(s.started).inDays > 1) {
        return streakdays;
        } else if (current.difference(s.started).inDays == 1 || day != s.started.day) {
        streakdays++;
        day = s.started.day;
        current = s.started;
        } else {
        current = s.started;
        continue;
       }
      }
    u.log.d("streakdays: $streakdays");
    return streakdays;
  }

  // backup db
  Future<Uint8List> dumpDb() async {
    final path = join(await getDatabasesPath(), _databaseName);

    return File(path).readAsBytesSync();
  }

  Future<void> restoreDb(String sourcePath) async {
    final path = join(await getDatabasesPath(), _databaseName);
    await File(sourcePath).copy(path);
  }
 }
