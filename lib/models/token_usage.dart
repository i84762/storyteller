class TokenUsage {
  final int dailyRequestsUsed;
  final int dailyTokensUsed;
  final int purchasedTokensRemaining;
  final DateTime lastResetDate;

  const TokenUsage({
    this.dailyRequestsUsed = 0,
    this.dailyTokensUsed = 0,
    this.purchasedTokensRemaining = 0,
    required this.lastResetDate,
  });

  TokenUsage copyWith({
    int? dailyRequestsUsed,
    int? dailyTokensUsed,
    int? purchasedTokensRemaining,
    DateTime? lastResetDate,
  }) {
    return TokenUsage(
      dailyRequestsUsed: dailyRequestsUsed ?? this.dailyRequestsUsed,
      dailyTokensUsed: dailyTokensUsed ?? this.dailyTokensUsed,
      purchasedTokensRemaining:
          purchasedTokensRemaining ?? this.purchasedTokensRemaining,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyRequestsUsed': dailyRequestsUsed,
        'dailyTokensUsed': dailyTokensUsed,
        'purchasedTokensRemaining': purchasedTokensRemaining,
        'lastResetDate': lastResetDate.toIso8601String(),
      };

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        dailyRequestsUsed: json['dailyRequestsUsed'] ?? 0,
        dailyTokensUsed: json['dailyTokensUsed'] ?? 0,
        purchasedTokensRemaining: json['purchasedTokensRemaining'] ?? 0,
        lastResetDate: DateTime.parse(json['lastResetDate']),
      );
}
