import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ai_source.dart';
import '../models/listening_mode.dart';
import '../models/subscription_tier.dart';
import '../models/intent_result.dart';
import '../utils/constants.dart';
import '../utils/intent_parser.dart';
import 'gemini_service.dart';
import 'openai_service.dart';
import 'on_device_service.dart' show OnDeviceService, OnDeviceUnavailableException;
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

  /// Checks whether on-device AI (Gemini Nano via AICore) is available.
  Future<bool> checkOnDeviceAvailability() => _onDeviceService.isAvailable();

  /// Expose service for UI-level status/download flows.
  OnDeviceService get onDeviceService => _onDeviceService;

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

  /// Transforms raw page text according to the active [ListeningMode].
  /// When [targetLanguage] is set, the AI responds in that language.
  /// Falls back to [pageText] on error.
  Future<String> transformPageForMode(
    String pageText,
    ListeningMode mode, {
    String? focusTopic,
    String? targetLanguage,
  }) async {
    if (mode == ListeningMode.wordToWord && targetLanguage == null) {
      return pageText;
    }
    if (pageText.trim().isEmpty) return pageText;
    final systemPrompt = AppConstants.listeningModePrompt(
      mode,
      focusTopic: focusTopic,
      targetLanguage: targetLanguage,
    );
    if (systemPrompt.isEmpty) return pageText;
    return _generate(
      systemPrompt: systemPrompt,
      userPrompt: pageText,
      maxOutputTokens: 1024,
    );
  }

  // ─── Core routing logic ───────────────────────────────────────────────────

  Future<String> _generate({
    required String systemPrompt,
    required String userPrompt,
    int maxOutputTokens = 512,
  }) async {
    switch (_currentTier) {
      case SubscriptionTier.free:
        return _generateFree(systemPrompt, userPrompt,
            maxOutputTokens: maxOutputTokens);
      case SubscriptionTier.premium:
        return _generatePremium(systemPrompt, userPrompt,
            maxOutputTokens: maxOutputTokens);
      case SubscriptionTier.byok:
        return _generateByok(systemPrompt, userPrompt,
            maxOutputTokens: maxOutputTokens);
      case SubscriptionTier.onDevice:
        return _generateOnDevice(systemPrompt, userPrompt);
    }
  }

  Future<String> _generateFree(
    String system,
    String user, {
    int maxOutputTokens = 512,
  }) async {
    final limitReached = await _usageTracker.isFreeLimitReached();
    if (limitReached) throw FreeLimitReachedException();
    final service = GeminiService(apiKey: AppConstants.devGeminiApiKey);
    final response = await service.generateContent(system, user,
        maxOutputTokens: maxOutputTokens);
    await _usageTracker.recordRequest(
        tokensUsed: service.estimateTokens(user + response));
    return response;
  }

  Future<String> _generatePremium(
    String system,
    String user, {
    int maxOutputTokens = 512,
  }) async {
    final usage = await _usageTracker.getUsage();
    if (usage.purchasedTokensRemaining <= 0) throw InsufficientTokensException();
    final service = GeminiService(
      apiKey: AppConstants.devGeminiApiKey,
      model: AppConstants.geminiProModel,
    );
    final response = await service.generateContent(system, user,
        maxOutputTokens: maxOutputTokens);
    final tokens = service.estimateTokens(user + response);
    await _usageTracker.deductPurchasedTokens(tokens);
    return response;
  }

  Future<String> _generateByok(
    String system,
    String user, {
    int maxOutputTokens = 512,
  }) async {
    if (_byokApiKey == null || _byokApiKey!.isEmpty) throw MissingApiKeyException();
    if (_byokProvider == AIProvider.openAICloud) {
      final service = OpenAIService(apiKey: _byokApiKey!);
      return service.generateContent(system, user,
          maxOutputTokens: maxOutputTokens);
    } else {
      final service = GeminiService(apiKey: _byokApiKey!);
      return service.generateContent(system, user,
          maxOutputTokens: maxOutputTokens);
    }
  }

  Future<String> _generateOnDevice(String system, String user) async {
    try {
      return await _onDeviceService.generateContent(system, user);
    } on OnDeviceUnavailableException {
      rethrow; // caller will surface this to the user
    }
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
