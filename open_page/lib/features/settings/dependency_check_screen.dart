import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/storage/book_dao.dart';
import '../../core/storage/bookmark_dao.dart';
import 'dart:io';

final statusProvider = StateProvider<String>((ref) => 'Initializing...');

class DependencyCheckScreen extends ConsumerStatefulWidget {
  const DependencyCheckScreen({super.key});

  @override
  ConsumerState<DependencyCheckScreen> createState() => _DependencyCheckScreenState();
}

class _DependencyCheckScreenState extends ConsumerState<DependencyCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  Future<void> _checkDependencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'SharedPrefs Works!');
      
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docDir.path}/test.db';
      final db = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
        await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      });
      await db.insert('Test', {'name': 'SQLite Works!'});
      await db.close();

      const uuid = Uuid();
      final id = uuid.v4();

      ref.read(statusProvider.notifier).state = 
        'Success!\n'
        'Riverpod: Active\n'
        'Prefs: ${prefs.getString('test_key')}\n'
        'SQLite: Records inserted\n'
        'UUID: $id';
    } catch (e) {
      ref.read(statusProvider.notifier).state = 'Error: $e';
    }
  }

  Future<void> _openMockReader() async {
    final docDir = await getApplicationDocumentsDirectory();
    final mockBookDir = Directory('${docDir.path}/books/mock_book');
    if (!await mockBookDir.exists()) {
      await mockBookDir.create(recursive: true);
    }

    final cssFile = File('${mockBookDir.path}/style.css');
    await cssFile.writeAsString('body { background-color: #f0f0f0; font-family: sans-serif; padding: 20px; } h1 { color: #512da8; } .box { border: 2px solid #512da8; padding: 10px; margin-top: 10px; }');

    final htmlFile = File('${mockBookDir.path}/index.html');
    await htmlFile.writeAsString('''
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Extracted Chapter</h1>
    <p>This is a real chapter rendered from local storage.</p>
    <div class="box">
        <p>CSS styling is working if this box has a border.</p>
    </div>
    <p>Image below:</p>
</body>
</html>
''');

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/reader',
        arguments: {'path': htmlFile.path},
      );
    }
  }

  Future<void> _testDatabase() async {
    final bookDao = BookDao();
    final bookmarkDao = BookmarkDao();
    final uuid = const Uuid();

    try {
      final bookId = uuid.v4();
      final book = BookRecord(
        id: bookId,
        title: 'Test Book',
        author: 'Antigravity',
        rootPath: '/mock/path',
      );

      await bookDao.insertBook(book);
      final books = await bookDao.getBooks();
      
      final bookmark = BookmarkRecord(
        id: uuid.v4(),
        bookId: bookId,
        chapter: 'Chapter 1',
        offset: 0.5,
        createdAt: DateTime.now().toIso8601String(),
      );
      await bookmarkDao.insertBookmark(bookmark);
      final bookmarks = await bookmarkDao.getBookmarksForBook(bookId);

      if (mounted) {
        ref.read(statusProvider.notifier).state = 
          'Database Test Success!\n'
          'Books in DB: ${books.length}\n'
          'Bookmarks for Test Book: ${bookmarks.length}';
      }
    } catch (e) {
      if (mounted) {
        ref.read(statusProvider.notifier).state = 'Database Test Error: $e';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(statusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dependency Check')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _openMockReader,
                child: const Text('Open Mock Reader'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testDatabase,
                child: const Text('Test Database DAOs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
