import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user.dart';
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'requests.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE requests('
          'id TEXT PRIMARY KEY, '
          'name TEXT, '
          'goods_required TEXT, '
          'quantity TEXT, '
          'address TEXT, '
          'phone_no TEXT, '
          'timestamp TEXT, '
          'type TEXT)',
        );
        await db.execute(
          'CREATE TABLE users('
          'username TEXT PRIMARY KEY, '
          'password TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE requests ADD COLUMN type TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'CREATE TABLE users('
            'username TEXT PRIMARY KEY, '
            'password TEXT)',
          );
        }
      },
    );
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> deleteUser(String username) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // Your other methods...

  Future<void> insertRequest(Map<String, dynamic> request) async {
    final db = await database;
    await db.insert(
      'requests',
      request,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAllRequests() async {
    final db = await database;
    await db.delete('requests');
  }

  Future<void> deleteAllReceivedRequests() async {
    final db = await database;
    await db.delete(
      'requests',
      where: 'type = ?',
      whereArgs: ['received'],
    );
  }

  Future<void> deleteAllSentRequests() async {
    final db = await database;
    await db.delete(
      'requests',
      where: 'type = ?',
      whereArgs: ['sent'],
    );
  }

  Future<List<Map<String, dynamic>>> getRequests() async {
    final db = await database;
    return db.query('requests');
  }

  Future<void> deleteExpiredRequests() async {
    final db = await database;
    final now = DateTime.now();
    await db.delete(
      'requests',
      where: 'timestamp < ? AND type = ?',
      whereArgs: [now.subtract(Duration(hours: 24)).toIso8601String(), 'received'],
    );
  }

  Future<void> deleteRequest(String id) async {
    final db = await database;
    await db.delete(
      'requests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
