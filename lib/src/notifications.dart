import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'ps4_timer_alarm';
  static const String channelName = 'PS4 Timer Alerts';
  static const String channelDescription =
      'Alerts for fixed PS4 timer sessions';
  static const MethodChannel _alarmSoundChannel =
      MethodChannel('ps4timer/alarm_sound');

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        final String timeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZone));
      } catch (_) {
        // Fallback to the default timezone database location.
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
    await _createAndroidChannel();
  }

  Future<void> _createAndroidChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }
    final Int64List vibrationPattern =
        Int64List.fromList(<int>[0, 1200, 300, 1200, 300, 1800]);
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  Future<bool> requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final bool? granted =
          await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    final bool? iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return iosGranted ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return true;
    }
    final bool? granted = await androidPlugin.requestExactAlarmsPermission();
    return granted ?? false;
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<String?> pickRingtone() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _alarmSoundChannel.invokeMethod<String>('pickRingtone');
    } catch (_) {
      return null;
    }
  }

  Future<void> scheduleSessionAlert({
    required int notificationId,
    required String title,
    required String body,
    required String deviceName,
    required DateTime scheduledAt,
    String? soundUri,
  }) async {
    final String? finalAlarmUri = soundUri ?? await _alarmUri();

    final tz.TZDateTime tzScheduledAt =
        tz.TZDateTime.from(scheduledAt, tz.local);
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ongoing: false,
      autoCancel: true,
      visibility: NotificationVisibility.public,
      sound: finalAlarmUri == null
          ? null
          : UriAndroidNotificationSound(finalAlarmUri),
      ticker: 'PS4 Timer Manager',
    );
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledAt,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: deviceName,
    );
  }

  Future<void> showImmediateAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    final String? alarmUri = await _alarmUri();
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      sound: alarmUri == null ? null : UriAndroidNotificationSound(alarmUri),
      ticker: 'PS4 Timer Manager',
    );
    await _plugin.show(
        id, title, body, NotificationDetails(android: androidDetails));
  }

  Future<String?> _alarmUri() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      return await _alarmSoundChannel.invokeMethod<String>('getAlarmUri');
    } catch (_) {
      return null;
    }
  }
}
