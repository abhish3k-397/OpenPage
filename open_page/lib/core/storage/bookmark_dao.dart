import 'package:sqflite/sqflite.dart';
import 'database.dart';

class BookmarkRecord {
  final String id;
  final String bookId;
  final String chapter;
  final double offset;
  final String createdAt;

  BookmarkRecord({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.offset,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'offset': offset,
      'created_at': createdAt,
    };
  }

  factory BookmarkRecord.fromMap(Map<String, dynamic> map) {
    return BookmarkRecord(
      id: map['id'],
      bookId: map['book_id'],
      chapter: map['chapter'],
      offset: map['offset'],
      createdAt: map['created_at'],
    );
  }
}

class BookmarkDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertBookmark(BookmarkRecord bookmark) async {
    final db = await _dbHelper.database;
    await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BookmarkRecord>> getBookmarksForBook(String bookId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => BookmarkRecord.fromMap(maps[i]));
  }

  Future<void> deleteBookmark(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
