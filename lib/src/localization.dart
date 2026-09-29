import 'package:flutter/material.dart';

import 'models.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isArabic => locale.languageCode == 'ar';

  Map<String, String> get _strings => isArabic ? _arabic : _english;

  String get appTitle => _strings['appTitle']!;
  String get devices => _strings['devices']!;
  String get activeSessions => _strings['activeSessions']!;
  String get history => _strings['history']!;
  String get settings => _strings['settings']!;
  String get addDevices => _strings['addDevices']!;
  String get addDevice => _strings['addDevice']!;
  String get startSession => _strings['startSession']!;
  String get newSession => _strings['newSession']!;
  String get openSession => _strings['openSession']!;
  String get fixedSession => _strings['fixedSession']!;
  String get customerNameOptional => _strings['customerNameOptional']!;
  String get durationMinutes => _strings['durationMinutes']!;
  String get pricePerHour => _strings['pricePerHour']!;
  String get available => _strings['available']!;
  String get busy => _strings['busy']!;
  String get usedTime => _strings['usedTime']!;
  String get remainingTime => _strings['remainingTime']!;
  String get elapsedTime => _strings['elapsedTime']!;
  String get extendTime => _strings['extendTime']!;
  String get stopSession => _strings['stopSession']!;
  String get save => _strings['save']!;
  String get cancel => _strings['cancel']!;
  String get language => _strings['language']!;
  String get theme => _strings['theme']!;
  String get system => _strings['system']!;
  String get light => _strings['light']!;
  String get dark => _strings['dark']!;
  String get hourlyRate => _strings['hourlyRate']!;
  String get defaultFixedDuration => _strings['defaultFixedDuration']!;
  String get noDevicesYet => _strings['noDevicesYet']!;
  String get noActiveSessions => _strings['noActiveSessions']!;
  String get noHistoryYet => _strings['noHistoryYet']!;
  String get currentSession => _strings['currentSession']!;
  String get sessionType => _strings['sessionType']!;
  String get customer => _strings['customer']!;
  String get amountDue => _strings['amountDue']!;
  String get startAt => _strings['startAt']!;
  String get endAt => _strings['endAt']!;
  String get sessionDuration => _strings['sessionDuration']!;
  String get deviceName => _strings['deviceName']!;
  String get addManyHint => _strings['addManyHint']!;
  String get deviceCount => _strings['deviceCount']!;
  String get fixedMinutesQuickPick => _strings['fixedMinutesQuickPick']!;
  String get requestNotifications => _strings['requestNotifications']!;
  String get requestExactAlarms => _strings['requestExactAlarms']!;
  String get languageSettingHint => _strings['languageSettingHint']!;
  String get themeSettingHint => _strings['themeSettingHint']!;
  String get ar => _strings['ar']!;
  String get en => _strings['en']!;
  String get deviceEndedMessage => _strings['deviceEndedMessage']!;
  String get extendBy => _strings['extendBy']!;
  String get minutes => _strings['minutes']!;
  String get reports => _strings['reports']!;
  String get today => _strings['today']!;
  String get totalDevices => _strings['totalDevices']!;
  String get totalRevenue => _strings['totalRevenue']!;
  String get totalSessions => _strings['totalSessions']!;
  String get activeNow => _strings['activeNow']!;
  String get retry => _strings['retry']!;
  String get deleteDevice => _strings['deleteDevice']!;
  String get confirmDeleteDevice => _strings['confirmDeleteDevice']!;
  String get delete => _strings['delete']!;
  String get cannotDeleteBusyDevice => _strings['cannotDeleteBusyDevice']!;
  String get permissionGranted => _strings['permissionGranted']!;
  String get permissionDenied => _strings['permissionDenied']!;
  String get deviceAddedSuccess => _strings['deviceAddedSuccess']!;
  String get changeRingtone => _strings['changeRingtone']!;
  String get pickRingtoneHint => _strings['pickRingtoneHint']!;
  String get yer => _strings['yer']!;

  String deviceLabel(int number) =>
      isArabic ? 'الجهاز $number' : 'Device $number';

  String sessionTypeLabel(SessionKind kind) {
    switch (kind) {
      case SessionKind.open:
        return openSession;
      case SessionKind.fixed:
        return fixedSession;
    }
  }

  String languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return system;
      case AppLanguage.en:
        return en;
      case AppLanguage.ar:
        return ar;
    }
  }

  String themeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return system;
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
    }
  }

  static const Map<String, String> _english = <String, String>{
    'appTitle': 'PS4 Timer Manager',
    'devices': 'Devices',
    'activeSessions': 'Active Sessions',
    'history': 'History',
    'settings': 'Settings',
    'addDevices': 'Add devices',
    'addDevice': 'Add device',
    'startSession': 'Start session',
    'newSession': 'New Session',
    'openSession': 'Open time',
    'fixedSession': 'Fixed time',
    'customerNameOptional': 'Customer name (optional)',
    'durationMinutes': 'Duration (minutes)',
    'pricePerHour': 'Price per hour',
    'available': 'Available',
    'busy': 'Busy',
    'usedTime': 'Used time',
    'remainingTime': 'Remaining time',
    'elapsedTime': 'Elapsed time',
    'extendTime': 'Extend time',
    'stopSession': 'Stop session',
    'save': 'Save',
    'cancel': 'Cancel',
    'language': 'Language',
    'theme': 'Theme',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'hourlyRate': 'Hourly rate',
    'defaultFixedDuration': 'Default fixed duration',
    'noDevicesYet': 'No devices yet. Add a device to start managing the shop.',
    'noActiveSessions': 'No active sessions right now.',
    'noHistoryYet': 'No completed sessions yet.',
    'currentSession': 'Current session',
    'sessionType': 'Session type',
    'customer': 'Customer',
    'amountDue': 'Amount due',
    'startAt': 'Start',
    'endAt': 'End',
    'sessionDuration': 'Duration',
    'deviceName': 'Device name',
    'addManyHint': 'Enter how many devices to create at once',
    'deviceCount': 'Device count',
    'fixedMinutesQuickPick': 'Quick durations',
    'requestNotifications': 'Request notifications',
    'requestExactAlarms': 'Request exact alarms',
    'languageSettingHint':
        'Choose Arabic or English. System follows the phone language.',
    'themeSettingHint': 'Choose how the app should look in the shop.',
    'ar': 'Arabic',
    'en': 'English',
    'deviceEndedMessage': 'Time has finished for device',
    'extendBy': 'Extend by',
    'minutes': 'minutes',
    'reports': 'Reports',
    'today': 'Today',
    'totalDevices': 'Total devices',
    'totalRevenue': 'Revenue',
    'totalSessions': 'Sessions',
    'activeNow': 'Active now',
    'retry': 'Retry',
    'deleteDevice': 'Delete Device',
    'confirmDeleteDevice': 'Are you sure you want to delete',
    'delete': 'Delete',
    'cannotDeleteBusyDevice':
        'Cannot delete a busy device. Stop the session first.',
    'permissionGranted': 'Permission granted successfully',
    'permissionDenied': 'Permission denied',
    'deviceAddedSuccess': 'Device added successfully',
    'changeRingtone': 'Notification Ringtone',
    'pickRingtoneHint': 'Choose a custom sound for the timer',
    'yer': 'YER',
  };

  static const Map<String, String> _arabic = <String, String>{
    'appTitle': 'PS4 Timer Manager',
    'devices': 'الأجهزة',
    'activeSessions': 'الجلسات النشطة',
    'history': 'السجل',
    'settings': 'الإعدادات',
    'addDevices': 'إضافة أجهزة',
    'addDevice': 'إضافة جهاز',
    'startSession': 'بدء الجلسة',
    'newSession': 'جلسة جديدة',
    'openSession': 'وقت مفتوح',
    'fixedSession': 'وقت محدد',
    'customerNameOptional': 'اسم الزبون (اختياري)',
    'durationMinutes': 'المدة (بالدقائق)',
    'pricePerHour': 'سعر الساعة',
    'available': 'متاح',
    'busy': 'مشغول',
    'usedTime': 'الوقت المستخدم',
    'remainingTime': 'الوقت المتبقي',
    'elapsedTime': 'الوقت المنقضي',
    'extendTime': 'تمديد الوقت',
    'stopSession': 'إيقاف الجلسة',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'language': 'اللغة',
    'theme': 'الوضع',
    'system': 'النظام',
    'light': 'فاتح',
    'dark': 'داكن',
    'hourlyRate': 'سعر الساعة',
    'defaultFixedDuration': 'المدة الافتراضية',
    'noDevicesYet': 'لا توجد أجهزة بعد. أضف جهازًا للبدء.',
    'noActiveSessions': 'لا توجد جلسات نشطة الآن.',
    'noHistoryYet': 'لا يوجد سجل جلسات مكتملة بعد.',
    'currentSession': 'الجلسة الحالية',
    'sessionType': 'نوع الجلسة',
    'customer': 'الزبون',
    'amountDue': 'المبلغ المستحق',
    'startAt': 'وقت البداية',
    'endAt': 'وقت النهاية',
    'sessionDuration': 'مدة اللعب',
    'deviceName': 'اسم الجهاز',
    'addManyHint': 'أدخل عدد الأجهزة التي تريد إضافتها دفعة واحدة',
    'deviceCount': 'عدد الأجهزة',
    'fixedMinutesQuickPick': 'اختصارات المدة',
    'requestNotifications': 'السماح بالإشعارات',
    'requestExactAlarms': 'السماح بالتنبيهات الدقيقة',
    'languageSettingHint':
        'اختر العربية أو الإنجليزية. النظام يتبع لغة الهاتف.',
    'themeSettingHint': 'اختر شكل الواجهة داخل المحل.',
    'ar': 'العربية',
    'en': 'الإنجليزية',
    'deviceEndedMessage': 'انتهى وقت الجهاز رقم',
    'extendBy': 'تمديد بمقدار',
    'minutes': 'دقيقة',
    'reports': 'التقارير',
    'today': 'اليوم',
    'totalDevices': 'إجمالي الأجهزة',
    'totalRevenue': 'الإيرادات',
    'totalSessions': 'الجلسات',
    'activeNow': 'نشطة الآن',
    'retry': 'إعادة المحاولة',
    'deleteDevice': 'حذف الجهاز',
    'confirmDeleteDevice': 'هل أنت متأكد من حذف',
    'delete': 'حذف',
    'cannotDeleteBusyDevice': 'لا يمكن حذف جهاز مشغول. قم بإيقاف الجلسة أولاً.',
    'permissionGranted': 'تم منح الصلاحية بنجاح',
    'permissionDenied': 'تم رفض الصلاحية',
    'deviceAddedSuccess': 'تمت إضافة الجهاز بنجاح',
    'changeRingtone': 'نغمة الإشعارات',
    'pickRingtoneHint': 'اختر نغمة مخصصة عند انتهاء الوقت',
    'yer': 'ر.ي',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((Locale supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
