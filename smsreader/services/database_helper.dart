import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sms_reader.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.tableMessages}(
            ${AppConstants.colId} INTEGER PRIMARY KEY,
            ${AppConstants.colAddress} TEXT,
            ${AppConstants.colBody} TEXT,
            ${AppConstants.colDate} INTEGER,
            ${AppConstants.colCategory} TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE ${AppConstants.tableMessages} ADD COLUMN ${AppConstants.colCategory} TEXT',
          );
        }
      },
    );
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      AppConstants.tableMessages,
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> batchInsertMessages(List<Map<String, dynamic>> messages) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var message in messages) {
        await txn.insert(
          AppConstants.tableMessages,
          message,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    return await db.query(
      AppConstants.tableMessages,
      orderBy: '${AppConstants.colDate} DESC',
    );
  }

  Future<Set<int>> getAllMessageIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMessages,
      columns: [AppConstants.colId],
    );
    return maps.map((m) => m[AppConstants.colId] as int).toSet();
  }

  Future<bool> messageExists(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMessages,
      where: '${AppConstants.colId} = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty;
  }
}
