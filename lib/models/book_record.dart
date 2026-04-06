class BookRecord {
  final String path;
  final String title;
  final int lastPage;
  final int totalPages;
  final DateTime lastOpened;
  final bool isPinned;

  const BookRecord({
    required this.path,
    required this.title,
    required this.lastPage,
    required this.totalPages,
    required this.lastOpened,
    this.isPinned = false,
  });

  BookRecord copyWith({
    int? lastPage,
    int? totalPages,
    DateTime? lastOpened,
    bool? isPinned,
  }) =>
      BookRecord(
        path: path,
        title: title,
        lastPage: lastPage ?? this.lastPage,
        totalPages: totalPages ?? this.totalPages,
        lastOpened: lastOpened ?? this.lastOpened,
        isPinned: isPinned ?? this.isPinned,
      );

  double get progress =>
      totalPages > 0 ? (lastPage + 1) / totalPages : 0.0;

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'lastPage': lastPage,
        'totalPages': totalPages,
        'lastOpened': lastOpened.toIso8601String(),
        'isPinned': isPinned,
      };

  factory BookRecord.fromJson(Map<String, dynamic> json) => BookRecord(
        path: json['path'] as String,
        title: json['title'] as String,
        lastPage: json['lastPage'] as int,
        totalPages: json['totalPages'] as int,
        lastOpened: DateTime.parse(json['lastOpened'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
      );
}
