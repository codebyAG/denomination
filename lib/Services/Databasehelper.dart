import 'dart:developer';
import 'package:denomination/Models/dinomation_entry_model.dart';
import 'package:denomination/Models/dinomination_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'mydinomination.db'; // Database name
  static const _databaseVersion = 1;

  // Table for storing Denomination Entries
  static const denominationEntryTable = 'denomination_entries';
  static const columnEntryId = 'entryId'; // Primary key for DenominationEntry
  static const columnDate = 'date';
  static const columnRemarks = 'remarks';
  static const columnCategory = 'category';

  // Table for storing Denominations (linked to DenominationEntry)
  static const denominationTable = 'denominations';
  static const columnNoteType = 'noteType';
  static const columnNumberOfNotes = 'numberOfNotes';
  static const columnTotalValue = 'totalValue';
  static const columnEntryIdFk = 'entryId'; // Foreign key to DenominationEntry

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database and create tables if they don't exist
  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    return openDatabase(path, version: _databaseVersion,
        onCreate: (db, version) async {
      // Create the DenominationEntry table
      await db.execute('''
        CREATE TABLE $denominationEntryTable (
          $columnEntryId INTEGER PRIMARY KEY,
          $columnDate TEXT,
          $columnRemarks TEXT,
          $columnCategory TEXT
        )
      ''');

      // Create the Denominations table
      await db.execute('''
        CREATE TABLE $denominationTable (
          id INTEGER PRIMARY KEY,
          $columnNoteType INTEGER,
          $columnNumberOfNotes INTEGER,
          $columnTotalValue INTEGER,
          $columnEntryIdFk INTEGER,
          FOREIGN KEY($columnEntryIdFk) REFERENCES $denominationEntryTable($columnEntryId)
        )
      ''');
    });
  }

  // Insert a DenominationEntry and its Denominations
  Future<int> insertDenominationEntry(DenominationEntry entry) async {
    Database db = await database;

    // Insert DenominationEntry
    int entryId = await db.insert(denominationEntryTable, {
      columnDate: entry.date,
      columnRemarks: entry.remarks,
      columnCategory: entry.category,
    });

    // Insert each Denomination, linking them to the entryId
    for (var denomination in entry.denominations) {
      denomination.entryId = entryId; // Set the entryId for the denomination
      await db.insert(
          denominationTable, denomination.toMapWithEntryId(entryId));
    }

    return entryId; // Return the inserted entryId
  }

  // Get all Denomination Entries along with their Denominations
  Future<List<DenominationEntry>> getAllDenominationEntries() async {
    Database db = await database;

    // Get all Denomination Entries
    var entryResult = await db.query(denominationEntryTable);

    List<DenominationEntry> entries = [];

    for (var entry in entryResult) {
      int entryId = entry[columnEntryId] as int;

      // Get associated Denominations for each DenominationEntry
      var denominationResult = await db.query(
        denominationTable,
        where: '$columnEntryIdFk = ?',
        whereArgs: [entryId],
      );
      log(denominationResult.toString());

      List<Denomination> denominations = denominationResult.isNotEmpty
          ? denominationResult.map((e) => Denomination.fromMap(e)).toList()
          : [];

      entries.add(
          DenominationEntry.fromMapWithDenominations(entry, denominations));
    }

    return entries;
  }

  // Update a DenominationEntry and its associated Denominations
  Future<int> updateDenominationEntry(DenominationEntry entry) async {
    Database db = await database;
    return await db.update(
        denominationEntryTable, entry.toMapWithoutDenominations(),
        where: '$columnEntryId = ?', whereArgs: [entry.id]);
  }

  // Delete a DenominationEntry and all its Denominations
  Future<int> deleteDenominationEntry(int entryId) async {
    Database db = await database;

    // Delete associated Denominations first
    await db.delete(denominationTable,
        where: '$columnEntryIdFk = ?', whereArgs: [entryId]);

    // Then delete the DenominationEntry itself
    return await db.delete(denominationEntryTable,
        where: '$columnEntryId = ?', whereArgs: [entryId]);
  }

  // Delete all data from the tables
  Future<int> deleteAllData() async {
    Database db = await database;

    // Delete all data from both tables
    await db.delete(denominationTable); // Deleting Denominations first
    return await db
        .delete(denominationEntryTable); // Then deleting DenominationEntries
  }
}
