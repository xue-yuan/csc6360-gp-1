import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static const int _databaseVersion = 2;
  static const expenseTable = 'expenses';

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY,
        name VARCHAR(63),
        amount REAL,
        category VARCHAR(31),
        date DATETIME
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY,
        name VARCHAR(63),
        amount REAL,
        category VARCHAR(31),
        date DATETIME
      )
    ''');
    }
  }

  Future<int> insertExpense(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(expenseTable, row);
  }

  Future<List<Map<String, dynamic>>> getExpensesByDate(DateTime date) async {
    Database db = await instance.database;
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return await db
        .query(expenseTable, where: 'date = ?', whereArgs: [formattedDate]);
  }

  Future<List<Map<String, dynamic>>> getExpensesByThisMonth(
      DateTime date) async {
    Database db = await instance.database;
    DateTime startDate = DateTime(date.year, date.month, 1);
    DateTime endDate = DateTime(date.year, date.month + 1, 0);
    String formattedStartDate =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    String formattedEndDate =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    return await db.query(expenseTable,
        where: 'date >= ? AND date <= ?',
        whereArgs: [formattedStartDate, formattedEndDate]);
  }
}

  Future<void> updateExpense(int id, String name, double amount,
      String category, DateTime date) async {
    Database db = await instance.database;
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    await db.update(
      expenseTable,
      {
        'name': name,
        'amount': amount,
        'category': category,
        'date': formattedDate
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpenseById(int id) async {
    Database db = await instance.database;
    await db.delete(expenseTable, where: 'id = ?', whereArgs: [id]);
  }
