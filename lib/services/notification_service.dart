import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps flutter_local_notifications for offline-processing progress/completion.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'offline_processing';
  static const _channelName = 'Offline Processing';
  static const _notifId = 0;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showProgress({
    required String bookTitle,
    required int textDone,
    required int imageDone,
    required int total,
    required bool includePictures,
  }) async {
    final isImagePhase = includePictures && textDone >= total;
    final progress = isImagePhase ? imageDone : textDone;
    final phaseLabel = isImagePhase
        ? 'Generating illustrations ($imageDone/$total)'
        : 'Processing text ($textDone/$total)';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: total,
      progress: progress,
      ongoing: true,
      subText: bookTitle,
    );
    await _plugin.show(
      _notifId,
      isImagePhase ? '🎨 Illustrating "$bookTitle"' : '📚 Processing "$bookTitle"',
      phaseLabel,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showComplete(String bookTitle,
      {bool withPictures = false}) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    await _plugin.show(
      _notifId,
      '✓ Offline Ready',
      withPictures
          ? '"$bookTitle" is ready offline — text + illustrations included.'
          : '"$bookTitle" is ready to read offline.',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel() async => _plugin.cancel(_notifId);
}
