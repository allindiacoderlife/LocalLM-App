import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadNotificationService {
  static final DownloadNotificationService _instance =
      DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'model_download_channel';
  static const String _channelName = 'Download Manager';
  static const String _channelDesc =
      'Shows live download progress and speed for offline AI models';

  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notifications.initialize(initSettings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const androidChannel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.low, // Silent updates for progress bars
          enableVibration: false,
          playSound: false,
        );
        await androidPlugin.createNotificationChannel(androidChannel);
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initialized = true;
    } catch (e) {
      // Prevent notification initialization failure on simulators from halting the app
      _initialized = true;
    }
  }

  Future<void> showProgress({
    required int id,
    required String modelName,
    required int progressPercent,
    required String speed,
    required String eta,
    required int downloadedMb,
    required int totalMb,
  }) async {
    try {
      await init();

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent,
        ongoing: true,
        onlyAlertOnce: true,
        autoCancel: false,
        actions: [
          const AndroidNotificationAction('cancel_download', 'Cancel'),
          const AndroidNotificationAction('pause_download', 'Pause'),
        ],
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final body = eta.isNotEmpty
          ? '$eta left, $speed'
          : speed;

      await _notifications.show(
        id,
        modelName,
        body,
        details,
      );
    } catch (_) {}
  }

  Future<void> showComplete({
    required int id,
    required String modelName,
  }) async {
    try {
      await init();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notifications.show(
        id,
        'Download complete',
        '$modelName is ready for local offline inference',
        details,
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }
}
