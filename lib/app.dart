import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/model_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/reader_provider.dart';
import 'screens/home_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/library_screen.dart';
import 'services/audio_handler.dart';

class StoryTellerApp extends StatefulWidget {
  const StoryTellerApp({super.key});

  @override
  State<StoryTellerApp> createState() => _StoryTellerAppState();
}

class _StoryTellerAppState extends State<StoryTellerApp>
    with WidgetsBindingObserver {
  // Providers are created once and held as fields so they survive rebuilds.
  ModelProvider? _modelProvider;
  SubscriptionProvider? _subProvider;
  ReaderProvider? _readerProvider;
  // true = audio_service failed; app runs with TTS only (no background service).
  bool _degradedMode = false;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First attempt after the first frame is drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInit());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retry when app resumes — ensures the Activity plugin binding is
  /// established (works around Samsung early windowStopped cycle).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _readerProvider == null) {
      _tryInit();
    }
  }

  void _tryInit() {
    if (_initializing || _readerProvider != null) return;
    _initAudioService();
  }

  static const AudioServiceConfig _audioConfig = AudioServiceConfig(
    androidNotificationChannelId: 'com.storyteller.storyteller.audio',
    androidNotificationChannelName: 'StoryTeller',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true,
    notificationColor: Color(0xFF16213E),
  );

  /// Tries to initialise audio_service with up to [maxAttempts] retries.
  /// Falls back to a plain TtsAudioHandler if all attempts fail so the app
  /// is always usable (TTS works; background media controls unavailable).
  Future<void> _initAudioService({int attempt = 0}) async {
    if (_initializing) return; // guard against concurrent invocations
    _initializing = true;

    const maxAttempts = 6;
    try {
      final handler = await AudioService.init<TtsAudioHandler>(
        builder: () => TtsAudioHandler(),
        config: _audioConfig,
      );
      if (!mounted) return;
      _setupProviders(handler);
    } catch (_) {
      _initializing = false;
      if (attempt < maxAttempts) {
        // Linear back-off: 500 ms, 1 s, 1.5 s …
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        if (mounted && _readerProvider == null) {
          _initAudioService(attempt: attempt + 1);
        }
      } else {
        // All retries exhausted — run in degraded mode (TTS only, no background service).
        if (mounted) _setupProvidersFallback();
      }
    }
  }

  void _setupProviders(TtsAudioHandler handler) {
    if (!mounted) return;
    setState(() {
      _modelProvider = ModelProvider()..init();
      _subProvider = SubscriptionProvider()..init();
      _readerProvider = ReaderProvider(handler)..init();
    });
  }

  /// Creates a raw TtsAudioHandler (not managed by AudioService) so the app
  /// still works without background media controls.
  void _setupProvidersFallback() {
    if (!mounted) return;
    setState(() {
      _degradedMode = true;
      _modelProvider = ModelProvider()..init();
      _subProvider = SubscriptionProvider()..init();
      _readerProvider = ReaderProvider(TtsAudioHandler())..init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a branded splash while AudioService is initialising.
    if (_readerProvider == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade900,
                    ]),
                  ),
                  child: const Icon(Icons.auto_stories,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'StoryTeller',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        // Use .value() so the same instances survive widget rebuilds.
        ChangeNotifierProvider<ModelProvider>.value(value: _modelProvider!),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: _subProvider!),
        ChangeNotifierProvider<ReaderProvider>.value(value: _readerProvider!),
        // Give ReaderProvider a reference to ModelProvider after both exist.
        ChangeNotifierProxyProvider<ModelProvider, ReaderProvider>(
          create: (ctx) => ctx.read<ReaderProvider>(),
          update: (ctx, modelProvider, readerProvider) {
            readerProvider!.modelProvider = modelProvider;
            return readerProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'StoryTeller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16213E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          cardTheme: CardThemeData(
            color: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const HomeScreen(),
          '/reader': (ctx) => const ReaderScreen(),
          '/settings': (ctx) => const SettingsScreen(),
          '/subscription': (ctx) => const SubscriptionScreen(),
          '/library': (ctx) => const LibraryScreen(),
        },
        // Show a one-time dismissible banner when running without background service.
        builder: _degradedMode
            ? (ctx, child) => Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      left: false,
                      right: false,
                      child: MaterialBanner(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        content: const Text(
                          'Background audio unavailable on this device.',
                          style: TextStyle(fontSize: 12),
                        ),
                        leading: const Icon(Icons.info_outline, size: 18),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _degradedMode = false),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: child!),
                  ],
                )
            : null,
      ),
    );
  }
}

