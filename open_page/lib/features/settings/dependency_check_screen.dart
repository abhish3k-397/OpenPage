import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/storage/book_dao.dart';
import '../../core/storage/bookmark_dao.dart';
import 'dart:io';

class StatusNotifier extends Notifier<String> {
  @override
  String build() => 'Initializing...';
  
  void setStatus(String status) => state = status;
}

final statusProvider = NotifierProvider<StatusNotifier, String>(StatusNotifier.new);

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

      if (mounted) {
        ref.read(statusProvider.notifier).setStatus(
          'Success!\n'
          'Riverpod: Active\n'
          'Prefs: ${prefs.getString('test_key')}\n'
          'SQLite: Records inserted\n'
          'UUID: $id',
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(statusProvider.notifier).setStatus('Error: $e');
      }
    }
  }

  Future<void> _openMockReader() async {
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/reader',
        arguments: {'bookId': 'mock-id'},
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
        ref.read(statusProvider.notifier).setStatus(
          'Database Test Success!\n'
          'Books in DB: ${books.length}\n'
          'Bookmarks for Test Book: ${bookmarks.length}',
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(statusProvider.notifier).setStatus('Database Test Error: $e');
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
