import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(statusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dependency Check')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
