import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/token_usage.dart';
import '../utils/constants.dart';

class UsageTracker {
  static const _key = 'token_usage';

  Future<TokenUsage> getUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return TokenUsage(lastResetDate: DateTime.now());
    }
    final usage = TokenUsage.fromJson(jsonDecode(raw));
    // Reset daily counters if a new day
    if (!_isSameDay(usage.lastResetDate, DateTime.now())) {
      final reset = usage.copyWith(
        dailyRequestsUsed: 0,
        dailyTokensUsed: 0,
        lastResetDate: DateTime.now(),
      );
      await _save(reset);
      return reset;
    }
    return usage;
  }

  Future<void> recordRequest({required int tokensUsed}) async {
    final usage = await getUsage();
    final updated = usage.copyWith(
      dailyRequestsUsed: usage.dailyRequestsUsed + 1,
      dailyTokensUsed: usage.dailyTokensUsed + tokensUsed,
    );
    await _save(updated);
  }

  Future<void> deductPurchasedTokens(int tokens) async {
    final usage = await getUsage();
    final updated = usage.copyWith(
      purchasedTokensRemaining:
          (usage.purchasedTokensRemaining - tokens).clamp(0, 999999),
    );
    await _save(updated);
  }

  Future<void> addPurchasedTokens(int tokens) async {
    final usage = await getUsage();
    final updated = usage.copyWith(
      purchasedTokensRemaining: usage.purchasedTokensRemaining + tokens,
    );
    await _save(updated);
  }

  Future<bool> isFreeLimitReached() async {
    final usage = await getUsage();
    return usage.dailyRequestsUsed >= AppConstants.freeDailyRequestLimit ||
        usage.dailyTokensUsed >= AppConstants.freeDailyTokenLimit;
  }

  Future<void> _save(TokenUsage usage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(usage.toJson()));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
