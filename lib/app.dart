import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/model_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/reader_provider.dart';
import 'screens/home_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';

class StoryTellerApp extends StatelessWidget {
  const StoryTellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelProvider()..init()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..init()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()..init()),
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
        },
      ),
    );
  }
}
