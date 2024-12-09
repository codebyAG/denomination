import 'package:denomination/Models/dinomation_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'mydinomination.db'; // Database name
  static const _databaseVersion = 1;

  static const table = 'denominations';
  static const columnId = 'id';
  static const columnNoteType = 'noteType';
  static const columnNumberOfNotes = 'numberOfNotes';
  static const columnTotalValue = 'totalValue';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database and create the table if it doesn't exist
  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    return openDatabase(path, version: _databaseVersion, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY,
          $columnNoteType INTEGER NOT NULL,
          $columnNumberOfNotes INTEGER NOT NULL,
          $columnTotalValue REAL NOT NULL
        )
      ''');
    });
  }

  // Insert a Denomination into the database
  Future<int> insertDenomination(Denomination denomination) async {
    Database db = await database;
    return await db.insert(table, denomination.toMap());
  }

  // Get all denominations from the database
  Future<List<Denomination>> getAllDenominations() async {
    Database db = await database;
    var result = await db.query(table);
    return result.isNotEmpty
        ? result.map((e) => Denomination.fromMap(e)).toList()
        : [];
  }

  // Update a Denomination
  Future<int> updateDenomination(Denomination denomination) async {
    Database db = await database;
    return await db.update(table, denomination.toMap(),
        where: '$columnId = ?', whereArgs: [denomination.id]);
  }

  // Delete a Denomination
  Future<int> deleteDenomination(int id) async {
    Database db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
