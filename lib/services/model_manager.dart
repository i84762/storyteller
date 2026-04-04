import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ai_source.dart';
import '../models/subscription_tier.dart';
import '../models/intent_result.dart';
import '../utils/constants.dart';
import '../utils/intent_parser.dart';
import 'gemini_service.dart';
import 'openai_service.dart';
import 'on_device_service.dart';
import 'usage_tracker.dart';

/// ModelManager is the central routing class.
/// It selects the correct LLM backend based on the user's subscription tier
/// and routes every request through that backend.
class ModelManager {
  final UsageTracker _usageTracker = UsageTracker();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final OnDeviceService _onDeviceService = OnDeviceService();

  SubscriptionTier _currentTier = SubscriptionTier.free;
  String? _byokApiKey;
  AIProvider _byokProvider = AIProvider.geminiCloud;

  SubscriptionTier get currentTier => _currentTier;
  String? get byokApiKey => _byokApiKey;

  // Called on app startup
  Future<void> init() async {
    final savedTier = await _secureStorage.read(key: 'subscription_tier');
    if (savedTier != null) {
      _currentTier = SubscriptionTier.values.firstWhere(
        (t) => t.name == savedTier,
        orElse: () => SubscriptionTier.free,
      );
    }
    _byokApiKey = await _secureStorage.read(key: 'byok_api_key');
    final savedProvider = await _secureStorage.read(key: 'byok_provider');
    if (savedProvider != null) {
      _byokProvider = AIProvider.values.firstWhere(
        (p) => p.name == savedProvider,
        orElse: () => AIProvider.geminiCloud,
      );
    }
  }

  Future<void> setTier(SubscriptionTier tier) async {
    _currentTier = tier;
    await _secureStorage.write(key: 'subscription_tier', value: tier.name);
  }

  Future<void> setByokKey(String key, AIProvider provider) async {
    _byokApiKey = key;
    _byokProvider = provider;
    await _secureStorage.write(key: 'byok_api_key', value: key);
    await _secureStorage.write(key: 'byok_provider', value: provider.name);
  }

  /// Determines intent from user's spoken input
  Future<IntentResult> classifyIntent(String spokenInput) async {
    final response = await _generate(
      systemPrompt: AppConstants.intentSystemPrompt,
      userPrompt: spokenInput,
    );
    return IntentParser.parse(response);
  }

  /// Sends a prompt with PDF context and returns the LLM's spoken response
  Future<String> respondToUser({
    required String userMessage,
    required String pdfContext,
  }) async {
    final systemPrompt = '${AppConstants.storySystemPrompt}\n\nDocument context:\n$pdfContext';
    return _generate(systemPrompt: systemPrompt, userPrompt: userMessage);
  }

  // ─── Core routing logic ───────────────────────────────────────────────────

  Future<String> _generate({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return _generateFree(systemPrompt, userPrompt);
      case SubscriptionTier.premium:
        return _generatePremium(systemPrompt, userPrompt);
      case SubscriptionTier.byok:
        return _generateByok(systemPrompt, userPrompt);
      case SubscriptionTier.onDevice:
        return _generateOnDevice(systemPrompt, userPrompt);
    }
  }

  Future<String> _generateFree(String system, String user) async {
    final limitReached = await _usageTracker.isFreeLimitReached();
    if (limitReached) {
      throw FreeLimitReachedException();
    }
    final service = GeminiService(apiKey: AppConstants.devGeminiApiKey);
    final response = await service.generateContent(system, user);
    await _usageTracker.recordRequest(
        tokensUsed: service.estimateTokens(user + response));
    return response;
  }

  Future<String> _generatePremium(String system, String user) async {
    final usage = await _usageTracker.getUsage();
    if (usage.purchasedTokensRemaining <= 0) {
      throw InsufficientTokensException();
    }
    final service = GeminiService(
      apiKey: AppConstants.devGeminiApiKey,
      model: AppConstants.geminiProModel,
    );
    final response = await service.generateContent(system, user);
    final tokens = service.estimateTokens(user + response);
    await _usageTracker.deductPurchasedTokens(tokens);
    return response;
  }

  Future<String> _generateByok(String system, String user) async {
    if (_byokApiKey == null || _byokApiKey!.isEmpty) {
      throw MissingApiKeyException();
    }
    if (_byokProvider == AIProvider.openAICloud) {
      final service = OpenAIService(apiKey: _byokApiKey!);
      return service.generateContent(system, user);
    } else {
      final service = GeminiService(apiKey: _byokApiKey!);
      return service.generateContent(system, user);
    }
  }

  Future<String> _generateOnDevice(String system, String user) async {
    return _onDeviceService.generateContent(system, user);
  }
}

class FreeLimitReachedException implements Exception {
  @override
  String toString() =>
      'FreeLimitReachedException: Daily free limit reached. Please upgrade.';
}

class InsufficientTokensException implements Exception {
  @override
  String toString() =>
      'InsufficientTokensException: No tokens remaining. Please purchase more.';
}

class MissingApiKeyException implements Exception {
  @override
  String toString() =>
      'MissingApiKeyException: No API key configured for BYOK mode.';
}
