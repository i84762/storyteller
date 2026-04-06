import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Persists AI-processed page text to a local SQLite database.
///
/// Cache key: (bookPath, pageIndex, mode, language, aiTier, tone)
/// Switching any of those parameters produces a fresh AI call the first time
/// and is then cached under the new key.
///
/// Entries survive app restarts and are only removed when the user removes
/// a book from the library (call [deleteForBook]) or explicitly clears all
/// ([deleteAll]).
class PageCacheService {
  static const _dbName = 'page_cache.db';
  static const _dbVersion = 2; // bumped: added tone column
  static const _table = 'page_cache';

  /// Sentinel value stored in the [language] column when no translation
  /// is requested (i.e. the original document language).
  static const _originalLang = '__original__';

  Database? _db;

  Future<void> init() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            book_path  TEXT    NOT NULL,
            page_index INTEGER NOT NULL,
            mode       TEXT    NOT NULL,
            language   TEXT    NOT NULL,
            ai_tier    TEXT    NOT NULL,
            tone       TEXT    NOT NULL DEFAULT '',
            content    TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (book_path, page_index, mode, language, ai_tier, tone)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_book_path ON $_table (book_path)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1→v2: added tone column; easiest migration is drop + recreate
        // (it's a cache — data loss is acceptable).
        await db.execute('DROP TABLE IF EXISTS $_table');
        await db.execute('''
          CREATE TABLE $_table (
            book_path  TEXT    NOT NULL,
            page_index INTEGER NOT NULL,
            mode       TEXT    NOT NULL,
            language   TEXT    NOT NULL,
            ai_tier    TEXT    NOT NULL,
            tone       TEXT    NOT NULL DEFAULT '',
            content    TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (book_path, page_index, mode, language, ai_tier, tone)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_book_path ON $_table (book_path)',
        );
      },
    );
  }

  /// Returns the cached AI output for the given key, or null on miss.
  Future<String?> get(
    String bookPath,
    int pageIndex,
    String mode,
    String? language,
    String aiTier,
    String tone,
  ) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.query(
        _table,
        columns: ['content'],
        where:
            'book_path = ? AND page_index = ? AND mode = ? AND language = ? AND ai_tier = ? AND tone = ?',
        whereArgs: [bookPath, pageIndex, mode, language ?? _originalLang, aiTier, tone],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['content'] as String;
    } catch (_) {
      return null;
    }
  }

  /// Stores [content] under the given key. Replaces any existing entry.
  Future<void> put(
    String bookPath,
    int pageIndex,
    String mode,
    String? language,
    String aiTier,
    String tone,
    String content,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.insert(
        _table,
        {
          'book_path': bookPath,
          'page_index': pageIndex,
          'mode': mode,
          'language': language ?? _originalLang,
          'ai_tier': aiTier,
          'tone': tone,
          'content': content,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Non-fatal — app still works, just without persistence for this entry.
    }
  }

  /// Removes all cached pages for [bookPath]. Call when the user removes a
  /// book from the library to free disk space.
  Future<void> deleteForBook(String bookPath) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.delete(_table, where: 'book_path = ?', whereArgs: [bookPath]);
    } catch (_) {}
  }

  /// Wipes the entire cache. Useful for a "Clear AI cache" settings option.
  Future<void> deleteAll() async {
    final db = _db;
    if (db == null) return;
    try {
      await db.delete(_table);
    } catch (_) {}
  }

  /// Returns the total number of cached entries (handy for a settings info row).
  Future<int> entryCount() async {
    final db = _db;
    if (db == null) return 0;
    try {
      final result =
          await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
      return (result.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Returns approximate disk usage in bytes.
  Future<int> sizeBytes() async {
    final db = _db;
    if (db == null) return 0;
    try {
      final result = await db.rawQuery(
        "SELECT page_count * page_size AS size FROM pragma_page_count(), pragma_page_size()",
      );
      return (result.first['size'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
