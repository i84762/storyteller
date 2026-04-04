import 'package:flutter/foundation.dart';
import '../models/ai_source.dart';
import '../models/subscription_tier.dart';
import '../models/token_usage.dart';
import '../services/model_manager.dart';
import '../services/usage_tracker.dart';

class ModelProvider extends ChangeNotifier {
  final ModelManager modelManager = ModelManager();
  final UsageTracker _usageTracker = UsageTracker();

  TokenUsage _usage = TokenUsage(lastResetDate: DateTime.now());
  bool _isLoading = false;
  String? _error;

  TokenUsage get usage => _usage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SubscriptionTier get currentTier => modelManager.currentTier;

  Future<void> init() async {
    await modelManager.init();
    await refreshUsage();
  }

  Future<void> switchTier(SubscriptionTier tier) async {
    await modelManager.setTier(tier);
    notifyListeners();
  }

  Future<void> setByokKey(String key, AIProvider provider) async {
    await modelManager.setByokKey(key, provider);
    notifyListeners();
  }

  Future<void> refreshUsage() async {
    _usage = await _usageTracker.getUsage();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> processUserInput({
    required String spokenInput,
    required String pdfContext,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First: classify intent (result used for future navigation handling)
      await modelManager.classifyIntent(spokenInput);

      // Then: generate response with full context
      final response = await modelManager.respondToUser(
        userMessage: spokenInput,
        pdfContext: pdfContext,
      );

      await refreshUsage();
      return response;
    } on FreeLimitReachedException {
      _error = 'free_limit_reached';
      return null;
    } on InsufficientTokensException {
      _error = 'insufficient_tokens';
      return null;
    } on MissingApiKeyException {
      _error = 'missing_api_key';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
