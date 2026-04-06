import 'dart:convert';
import 'listening_mode.dart';
import 'reading_tone.dart';

/// Stores the configuration and progress of an offline-processed book.
class OfflineConfig {
  final String bookPath;
  final ListeningMode mode;
  final ReadingTone tone;
  final String aiTier;
  final int totalPages;
  int processedPages;
  DateTime? processedAt;
  final bool isProcessing;

  OfflineConfig({
    required this.bookPath,
    required this.mode,
    required this.tone,
    required this.aiTier,
    required this.totalPages,
    this.processedPages = 0,
    this.processedAt,
    this.isProcessing = false,
  });

  bool get isComplete => totalPages > 0 && processedPages >= totalPages;
  double get progress => totalPages > 0 ? processedPages / totalPages : 0.0;

  String get bookTitle =>
      bookPath.split(RegExp(r'[/\\]')).last.replaceAll('.pdf', '');

  Map<String, dynamic> toJson() => {
        'bookPath': bookPath,
        'mode': mode.name,
        'tone': tone.name,
        'aiTier': aiTier,
        'totalPages': totalPages,
        'processedPages': processedPages,
        'processedAt': processedAt?.toIso8601String(),
        'isProcessing': isProcessing,
      };

  factory OfflineConfig.fromJson(Map<String, dynamic> json) {
    return OfflineConfig(
      bookPath: json['bookPath'] as String,
      mode: ListeningMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ListeningMode.wordToWord,
      ),
      tone: ReadingTone.values.firstWhere(
        (t) => t.name == json['tone'],
        orElse: () => ReadingTone.neutral,
      ),
      aiTier: json['aiTier'] as String? ?? 'free',
      totalPages: json['totalPages'] as int? ?? 0,
      processedPages: json['processedPages'] as int? ?? 0,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
      isProcessing: json['isProcessing'] as bool? ?? false,
    );
  }

  // ignore: unused_element
  static String _encode(List<OfflineConfig> list) =>
      jsonEncode(list.map((c) => c.toJson()).toList());
}
