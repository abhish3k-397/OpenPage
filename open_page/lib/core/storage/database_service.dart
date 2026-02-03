import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as developer;

class BookRecord {
  final String id;
  final String title;
  final String author;
  final String coverPath;
  final String extractPath;
  final DateTime lastReadDate;

  BookRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.coverPath,
    required this.extractPath,
    required this.lastReadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverPath': coverPath,
      'extractPath': extractPath,
      'lastReadDate': lastReadDate.toIso8601String(),
    };
  }

  factory BookRecord.fromMap(Map<String, dynamic> map) {
    return BookRecord(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      coverPath: map['coverPath'],
      extractPath: map['extractPath'],
      lastReadDate: DateTime.parse(map['lastReadDate']),
    );
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('open_page.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    developer.log('Creating database tables', name: 'DatabaseService');
    await db.execute('''
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT,
  coverPath TEXT,
  extractPath TEXT NOT NULL,
  lastReadDate TEXT NOT NULL
)
''');
  }

  Future<int> insertBook(BookRecord book) async {
    final db = await instance.database;
    return await db.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BookRecord>> getAllBooks() async {
    final db = await instance.database;
    final result = await db.query('books', orderBy: 'lastReadDate DESC');
    return result.map((json) => BookRecord.fromMap(json)).toList();
  }

  Future<int> deleteBook(String id) async {
    final db = await instance.database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
