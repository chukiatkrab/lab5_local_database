import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // NOTES
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        createdAt TEXT,
        deadline TEXT
      )
    ''');

    // TAGS
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    // RELATION
    await db.execute('''
      CREATE TABLE note_tags (
        noteId INTEGER,
        tagId INTEGER,
        PRIMARY KEY (noteId, tagId)
      )
    ''');
  }

  // ---------------- NOTES ----------------

  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    return await db.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'id DESC');
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id=?', whereArgs: [id]);
  }

  // ---------------- TAGS ----------------

  Future<int> insertTag(String name) async {
    final db = await instance.database;
    return await db.insert('tags', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await instance.database;
    return await db.query('tags');
  }

  // ---------------- RELATION ----------------

  Future<void> addTagToNote(int noteId, int tagId) async {
    final db = await instance.database;
    await db.insert('note_tags', {
      'noteId': noteId,
      'tagId': tagId,
    });
  }

  Future<List<Map<String, dynamic>>> getTagsByNote(int noteId) async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT tags.* FROM tags
      INNER JOIN note_tags ON tags.id = note_tags.tagId
      WHERE note_tags.noteId = ?
    ''', [noteId]);
  }
}