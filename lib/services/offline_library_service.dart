import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_config.dart';

/// Persists and retrieves [OfflineConfig] records via SharedPreferences.
class OfflineLibraryService {
  static const _key = 'offline_configs';
  final List<OfflineConfig> _configs = [];

  List<OfflineConfig> get configs => List.unmodifiable(_configs);

  List<OfflineConfig> forBook(String path) =>
      _configs.where((c) => c.bookPath == path).toList();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _configs.clear();
      _configs.addAll(
        list.map((e) => OfflineConfig.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  Future<void> save(OfflineConfig config) async {
    final idx = _configs.indexWhere(
      (c) =>
          c.bookPath == config.bookPath &&
          c.mode == config.mode &&
          c.tone == config.tone,
    );
    if (idx >= 0) {
      _configs[idx] = config;
    } else {
      _configs.add(config);
    }
    await _persist();
  }

  Future<void> remove(String bookPath) async {
    _configs.removeWhere((c) => c.bookPath == bookPath);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_configs.map((c) => c.toJson()).toList()),
    );
  }
}
