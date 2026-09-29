import 'dart:convert';

enum AppThemeMode { system, light, dark }

enum AppLanguage { system, en, ar }

enum SessionKind { open, fixed }

class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.number,
    this.customName,
  });

  final String id;
  final int number;
  final String? customName;

  DeviceModel copyWith({String? customName, int? number}) {
    return DeviceModel(
      id: id,
      number: number ?? this.number,
      customName: customName ?? this.customName,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'number': number,
        'customName': customName,
      };

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      number: (json['number'] as num).toInt(),
      customName: json['customName'] as String?,
    );
  }
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.deviceId,
    required this.deviceNumber,
    required this.deviceName,
    required this.customerName,
    required this.kind,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.amountPaid,
  });

  final String id;
  final String deviceId;
  final int deviceNumber;
  final String deviceName;
  final String customerName;
  final SessionKind kind;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double amountPaid;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deviceId': deviceId,
        'deviceNumber': deviceNumber,
        'deviceName': deviceName,
        'customerName': customerName,
        'kind': kind.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'amountPaid': amountPaid,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceNumber: (json['deviceNumber'] as num).toInt(),
      deviceName: json['deviceName'] as String,
      customerName: json['customerName'] as String? ?? '',
      kind: SessionKind.values.byName(json['kind'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
    );
  }

  String get serialised => jsonEncode(toJson());
}

class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.deviceId,
    required this.deviceNumber,
    required this.deviceName,
    required this.customerName,
    required this.kind,
    required this.startedAt,
    required this.plannedEndAt,
    required this.notificationId,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  final String id;
  final String deviceId;
  final int deviceNumber;
  final String deviceName;
  final String customerName;
  final SessionKind kind;
  final DateTime startedAt;
  final DateTime? plannedEndAt;
  final int? notificationId;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  bool get isFixed => kind == SessionKind.fixed;

  bool get isExpired =>
      plannedEndAt != null && DateTime.now().isAfter(plannedEndAt!);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'deviceId': deviceId,
        'deviceNumber': deviceNumber,
        'deviceName': deviceName,
        'customerName': customerName,
        'kind': kind.name,
        'startedAt': startedAt.toIso8601String(),
        'plannedEndAt': plannedEndAt?.toIso8601String(),
        'notificationId': notificationId,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceNumber: (json['deviceNumber'] as num).toInt(),
      deviceName: json['deviceName'] as String,
      customerName: json['customerName'] as String? ?? '',
      kind: SessionKind.values.byName(json['kind'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      plannedEndAt: _dateOrNull(json['plannedEndAt']),
      notificationId: (json['notificationId'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  ActiveSession copyWith({
    String? customerName,
    DateTime? plannedEndAt,
    int? notificationId,
    DateTime? lastUpdatedAt,
  }) {
    return ActiveSession(
      id: id,
      deviceId: deviceId,
      deviceNumber: deviceNumber,
      deviceName: deviceName,
      customerName: customerName ?? this.customerName,
      kind: kind,
      startedAt: startedAt,
      plannedEndAt: plannedEndAt ?? this.plannedEndAt,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Duration elapsedAt(DateTime now) => now.difference(startedAt);

  Duration? remainingAt(DateTime now) {
    if (plannedEndAt == null) {
      return null;
    }
    final Duration remaining = plannedEndAt!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static DateTime? _dateOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.hourlyRate,
    required this.defaultFixedMinutes,
    required this.startWithSystemLocale,
    this.customRingtoneUri,
  });

  final AppThemeMode themeMode;
  final AppLanguage language;
  final double hourlyRate;
  final int defaultFixedMinutes;
  final bool startWithSystemLocale;
  final String? customRingtoneUri;

  factory AppSettings.defaults() => const AppSettings(
        themeMode: AppThemeMode.system,
        language: AppLanguage.system,
        hourlyRate: 400, // تم التعديل إلى 400
        defaultFixedMinutes: 60,
        startWithSystemLocale: true,
        customRingtoneUri: null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'themeMode': themeMode.name,
        'language': language.name,
        'hourlyRate': hourlyRate,
        'defaultFixedMinutes': defaultFixedMinutes,
        'startWithSystemLocale': startWithSystemLocale,
        'customRingtoneUri': customRingtoneUri,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.byName(
        json['themeMode'] as String? ?? AppThemeMode.system.name,
      ),
      language: AppLanguage.values.byName(
        json['language'] as String? ?? AppLanguage.system.name,
      ),
      hourlyRate:
          (json['hourlyRate'] as num?)?.toDouble() ?? 400, // تم التعديل إلى 400
      defaultFixedMinutes: (json['defaultFixedMinutes'] as num?)?.toInt() ?? 60,
      startWithSystemLocale: (json['startWithSystemLocale'] as bool?) ?? true,
      customRingtoneUri: json['customRingtoneUri'] as String?,
    );
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    double? hourlyRate,
    int? defaultFixedMinutes,
    bool? startWithSystemLocale,
    String? customRingtoneUri,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      defaultFixedMinutes: defaultFixedMinutes ?? this.defaultFixedMinutes,
      startWithSystemLocale:
          startWithSystemLocale ?? this.startWithSystemLocale,
      customRingtoneUri: customRingtoneUri ?? this.customRingtoneUri,
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.settings,
    required this.devices,
    required this.activeSessions,
    required this.history,
    required this.nextSessionNumber,
    required this.nextNotificationId,
  });

  final AppSettings settings;
  final List<DeviceModel> devices;
  final List<ActiveSession> activeSessions;
  final List<SessionRecord> history;
  final int nextSessionNumber;
  final int nextNotificationId;

  factory AppSnapshot.defaults() => AppSnapshot(
        settings: AppSettings.defaults(),
        devices: <DeviceModel>[],
        activeSessions: <ActiveSession>[],
        history: <SessionRecord>[],
        nextSessionNumber: 1,
        nextNotificationId: 100,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'settings': settings.toJson(),
        'devices':
            devices.map((DeviceModel device) => device.toJson()).toList(),
        'activeSessions': activeSessions
            .map((ActiveSession session) => session.toJson())
            .toList(),
        'history': history.map((SessionRecord item) => item.toJson()).toList(),
        'nextSessionNumber': nextSessionNumber,
        'nextNotificationId': nextNotificationId,
      };

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    return AppSnapshot(
      settings: AppSettings.fromJson(
        Map<String, dynamic>.from(
            json['settings'] as Map? ?? <String, dynamic>{}),
      ),
      devices: (json['devices'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) =>
              DeviceModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      activeSessions: (json['activeSessions'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) =>
              ActiveSession.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      history: (json['history'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) =>
              SessionRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      nextSessionNumber: (json['nextSessionNumber'] as num?)?.toInt() ?? 1,
      nextNotificationId: (json['nextNotificationId'] as num?)?.toInt() ?? 100,
    );
  }
}
