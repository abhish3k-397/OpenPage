import 'package:sqflite/sqflite.dart';
import 'database.dart';

class BookRecord {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String rootPath;
  final String? lastChapter;
  final double? lastOffset;

  BookRecord({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.rootPath,
    this.lastChapter,
    this.lastOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_path': coverPath,
      'root_path': rootPath,
      'last_chapter': lastChapter,
      'last_offset': lastOffset,
    };
  }

  factory BookRecord.fromMap(Map<String, dynamic> map) {
    return BookRecord(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      coverPath: map['cover_path'],
      rootPath: map['root_path'],
      lastChapter: map['last_chapter'],
      lastOffset: map['last_offset'],
    );
  }
}

class BookDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertBook(BookRecord book) async {
    final db = await _dbHelper.database;
    await db.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BookRecord>> getBooks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i) => BookRecord.fromMap(maps[i]));
  }

  Future<BookRecord?> getBookById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BookRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateReadProgress(String id, String chapter, double offset) async {
    final db = await _dbHelper.database;
    await db.update(
      'books',
      {'last_chapter': chapter, 'last_offset': offset},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
