import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_record.dart';

/// Persists the user's last 20 opened books (plus unlimited pinned books).
/// Pinned books are never evicted. Non-pinned books beyond 20 are dropped
/// in oldest-first order.
class LibraryService {
  static const _kKey = 'recent_books';
  static const _maxNonPinned = 20;

  List<BookRecord> _books = [];

  /// All books sorted: pinned first (most-recent-first), then non-pinned
  /// (most-recent-first).
  List<BookRecord> get sortedBooks {
    final pinned = _books.where((b) => b.isPinned).toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    final unpinned = _books.where((b) => !b.isPinned).toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return [...pinned, ...unpinned];
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _books = list
          .map((e) => BookRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _books = [];
    }
  }

  void addOrUpdate(BookRecord record) {
    final idx = _books.indexWhere((b) => b.path == record.path);
    if (idx >= 0) {
      _books[idx] = _books[idx].copyWith(
        lastPage: record.lastPage,
        totalPages: record.totalPages,
        lastOpened: record.lastOpened,
      );
    } else {
      _books.insert(0, record);
      _evict();
    }
    _save().ignore();
  }

  void togglePin(String path) {
    final idx = _books.indexWhere((b) => b.path == path);
    if (idx < 0) return;
    _books[idx] = _books[idx].copyWith(isPinned: !_books[idx].isPinned);
    _save().ignore();
  }

  void remove(String path) {
    _books.removeWhere((b) => b.path == path);
    _save().ignore();
  }

  void _evict() {
    final nonPinned = _books.where((b) => !b.isPinned).toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    if (nonPinned.length > _maxNonPinned) {
      final toRemove =
          nonPinned.skip(_maxNonPinned).map((b) => b.path).toSet();
      _books.removeWhere((b) => toRemove.contains(b.path));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(_books.map((b) => b.toJson()).toList()),
    );
  }
}
