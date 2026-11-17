import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/alert_log.dart';
import '../models/family_member.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'panic_button.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE family_members (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            relation TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            addedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE alert_logs (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            isLastKnownLocation INTEGER NOT NULL DEFAULT 0,
            audioPath TEXT,
            message TEXT NOT NULL,
            sentVia TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Family Members CRUD
  Future<List<FamilyMember>> getFamilyMembers() async {
    final db = await database;
    final maps = await db.query('family_members', orderBy: 'addedAt DESC');
    return maps.map(FamilyMember.fromMap).toList();
  }

  Future<void> insertFamilyMember(FamilyMember member) async {
    final db = await database;
    await db.insert(
      'family_members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFamilyMember(String id) async {
    final db = await database;
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  Future<FamilyMember?> findMemberByCredentials(
    String email,
    String password,
  ) async {
    final db = await database;
    final maps = await db.query(
      'family_members',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
    );
    if (maps.isEmpty) return null;
    return FamilyMember.fromMap(maps.first);
  }

  // Alert Logs CRUD
  Future<List<AlertLog>> getAlertLogs() async {
    final db = await database;
    final maps = await db.query('alert_logs', orderBy: 'timestamp DESC');
    return maps.map(AlertLog.fromMap).toList();
  }

  Future<void> insertAlertLog(AlertLog log) async {
    final db = await database;
    await db.insert(
      'alert_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAlertLogs() async {
    final db = await database;
    await db.delete('alert_logs');
  }
}
