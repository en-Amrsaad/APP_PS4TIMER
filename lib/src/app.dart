import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'localization.dart';
import 'models.dart';
import 'notifications.dart';
import 'storage.dart';

class Ps4TimerApp extends StatelessWidget {
  const Ps4TimerApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, _) {
          final Locale? locale = controller.effectiveLocale;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context).appTitle,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: controller.effectiveThemeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const AppShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final Color seed = brightness == Brightness.dark
        ? const Color(0xFF0F766E)
        : const Color(0xFF165D62);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF08141A)
          : const Color(0xFFF3F8F8),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0B1720)
            : const Color(0xFFF3F8F8),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFF0E1B23)
            : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0B1720)
            : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF122531)
            : const Color(0xFFF5FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope(
      {super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}

class AppController extends ChangeNotifier {
  AppController() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  AppController.test({AppSnapshot? snapshot}) {
    _ticker = null;
    _snapshot = snapshot ?? AppSnapshot.defaults();
    _initialized = true;
  }

  final AppStorage _storage = AppStorage.instance;
  final NotificationService _notifications = NotificationService();

  Timer? _ticker;

  AppSnapshot _snapshot = AppSnapshot.defaults();
  bool _initialized = false;
  bool _busy = false;
  String? _errorMessage;

  AppSnapshot get snapshot => _snapshot;
  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;

  AppSettings get settings => _snapshot.settings;
  List<DeviceModel> get devices =>
      List<DeviceModel>.unmodifiable(_snapshot.devices);
  List<ActiveSession> get activeSessions =>
      List<ActiveSession>.unmodifiable(_snapshot.activeSessions);
  List<SessionRecord> get history =>
      List<SessionRecord>.unmodifiable(_snapshot.history.reversed);

  ThemeMode get effectiveThemeMode {
    switch (settings.themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Locale? get effectiveLocale {
    switch (settings.language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.ar:
        return const Locale('ar');
    }
  }

  Future<void> initialize() async {
    try {
      _snapshot = await _storage.loadSnapshot();
      await _notifications.initialize();
      await _notifications.requestNotificationPermission();
      _initialized = true;
      await _resyncExpiredNotifications();
      await _storage.saveSnapshot(_snapshot);
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() => initialize();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _persist() async {
    await _storage.saveSnapshot(_snapshot);
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void _onTick() {
    if (_snapshot.activeSessions.isNotEmpty) {
      notifyListeners();
    }
  }

  String _nextDeviceLabel(int number) =>
      _snapshot.settings.language == AppLanguage.ar
          ? 'الجهاز $number'
          : 'Device $number';

  Future<void> addDevices(int count) async {
    if (count <= 0) {
      return;
    }
    _setBusy(true);
    try {
      final List<DeviceModel> devices =
          List<DeviceModel>.from(_snapshot.devices);
      int nextNumber = devices.isEmpty
          ? 1
          : devices
                  .map((DeviceModel device) => device.number)
                  .reduce(math.max) +
              1;
      for (int i = 0; i < count; i++) {
        devices.add(
          DeviceModel(
            id: 'device_${DateTime.now().microsecondsSinceEpoch}_$i',
            number: nextNumber + i,
          ),
        );
      }
      _snapshot = AppSnapshot(
        settings: _snapshot.settings,
        devices: devices,
        activeSessions: _snapshot.activeSessions,
        history: _snapshot.history,
        nextSessionNumber: _snapshot.nextSessionNumber,
        nextNotificationId: _snapshot.nextNotificationId,
      );
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    if (activeSessionForDevice(deviceId) != null) {
      return;
    }
    _setBusy(true);
    try {
      final List<DeviceModel> devices =
          List<DeviceModel>.from(_snapshot.devices)
            ..removeWhere((DeviceModel d) => d.id == deviceId);

      _snapshot = AppSnapshot(
        settings: _snapshot.settings,
        devices: devices,
        activeSessions: _snapshot.activeSessions,
        history: _snapshot.history,
        nextSessionNumber: _snapshot.nextSessionNumber,
        nextNotificationId: _snapshot.nextNotificationId,
      );
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _setBusy(true);
    try {
      _snapshot = AppSnapshot(
        settings: newSettings,
        devices: _snapshot.devices,
        activeSessions: _snapshot.activeSessions,
        history: _snapshot.history,
        nextSessionNumber: _snapshot.nextSessionNumber,
        nextNotificationId: _snapshot.nextNotificationId,
      );
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> pickRingtone() async {
    final String? uri = await _notifications.pickRingtone();
    if (uri != null) {
      await updateSettings(settings.copyWith(customRingtoneUri: uri));
    }
  }

  DeviceModel? deviceById(String deviceId) {
    for (final DeviceModel device in _snapshot.devices) {
      if (device.id == deviceId) {
        return device;
      }
    }
    return null;
  }

  ActiveSession? activeSessionForDevice(String deviceId) {
    for (final ActiveSession session in _snapshot.activeSessions) {
      if (session.deviceId == deviceId) {
        return session;
      }
    }
    return null;
  }

  Future<void> startSession({
    required String deviceId,
    required SessionKind kind,
    String? customerName,
    int fixedMinutes = 60,
  }) async {
    fixedMinutes = math.max(1, fixedMinutes);
    final DeviceModel? device = deviceById(deviceId);
    if (device == null) {
      throw StateError('Device not found');
    }
    if (activeSessionForDevice(deviceId) != null) {
      throw StateError('This device is already busy');
    }

    _setBusy(true);
    try {
      final DateTime now = DateTime.now();
      final int sessionNumber = _snapshot.nextSessionNumber;
      final int? notificationId =
          kind == SessionKind.fixed ? _snapshot.nextNotificationId : null;
      final ActiveSession session = ActiveSession(
        id: 'session_$sessionNumber',
        deviceId: device.id,
        deviceNumber: device.number,
        deviceName: device.customName ?? _nextDeviceLabel(device.number),
        customerName: customerName?.trim() ?? '',
        kind: kind,
        startedAt: now,
        plannedEndAt: kind == SessionKind.fixed
            ? now.add(Duration(minutes: fixedMinutes))
            : null,
        notificationId: notificationId,
        createdAt: now,
        lastUpdatedAt: now,
      );

      final List<ActiveSession> activeSessions =
          List<ActiveSession>.from(_snapshot.activeSessions)..add(session);
      _snapshot = AppSnapshot(
        settings: _snapshot.settings,
        devices: _snapshot.devices,
        activeSessions: activeSessions,
        history: _snapshot.history,
        nextSessionNumber: _snapshot.nextSessionNumber + 1,
        nextNotificationId: kind == SessionKind.fixed
            ? _snapshot.nextNotificationId + 1
            : _snapshot.nextNotificationId,
      );

      if (kind == SessionKind.fixed) {
        final String notificationBody = settings.language == AppLanguage.ar
            ? 'انتهى وقت ${_deviceTitle(device)}'
            : 'Time is up for ${_deviceTitle(device)}';
        await _notifications.scheduleSessionAlert(
          notificationId: notificationId!,
          title: 'PS4 Timer Manager',
          body: notificationBody,
          deviceName: _deviceTitle(device),
          scheduledAt: session.plannedEndAt!,
          soundUri: settings.customRingtoneUri,
        );
      }

      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> extendSession(
      {required String sessionId, required int minutes}) async {
    if (minutes <= 0) {
      return;
    }
    final int index = _snapshot.activeSessions
        .indexWhere((ActiveSession session) => session.id == sessionId);
    if (index < 0) {
      return;
    }
    final ActiveSession current = _snapshot.activeSessions[index];
    final DateTime base = current.plannedEndAt ?? DateTime.now();
    final DateTime newEnd = base.add(Duration(minutes: minutes));
    final ActiveSession updated = current.copyWith(
      plannedEndAt: newEnd,
      lastUpdatedAt: DateTime.now(),
    );
    final List<ActiveSession> activeSessions =
        List<ActiveSession>.from(_snapshot.activeSessions)..[index] = updated;
    _snapshot = AppSnapshot(
      settings: _snapshot.settings,
      devices: _snapshot.devices,
      activeSessions: activeSessions,
      history: _snapshot.history,
      nextSessionNumber: _snapshot.nextSessionNumber,
      nextNotificationId: _snapshot.nextNotificationId,
    );
    if (updated.notificationId != null) {
      await _notifications.cancelNotification(updated.notificationId!);
      final String notificationBody = settings.language == AppLanguage.ar
          ? 'انتهى وقت ${updated.deviceName}'
          : 'Time is up for ${updated.deviceName}';
      await _notifications.scheduleSessionAlert(
        notificationId: updated.notificationId!,
        title: 'PS4 Timer Manager',
        body: notificationBody,
        deviceName: updated.deviceName,
        scheduledAt: newEnd,
        soundUri: settings.customRingtoneUri,
      );
    }
    await _persist();
  }

  Future<void> stopSession(String sessionId) async {
    final int index = _snapshot.activeSessions
        .indexWhere((ActiveSession session) => session.id == sessionId);
    if (index < 0) {
      return;
    }
    _setBusy(true);
    try {
      final ActiveSession current = _snapshot.activeSessions[index];
      final DateTime now = DateTime.now();
      final Duration duration = now.difference(current.startedAt);
      final double amount = calculateAmount(duration);
      final SessionRecord record = SessionRecord(
        id: current.id,
        deviceId: current.deviceId,
        deviceNumber: current.deviceNumber,
        deviceName: current.deviceName,
        customerName: current.customerName,
        kind: current.kind,
        startedAt: current.startedAt,
        endedAt: now,
        durationSeconds: duration.inSeconds,
        amountPaid: amount,
      );

      if (current.notificationId != null) {
        await _notifications.cancelNotification(current.notificationId!);
      }

      final List<ActiveSession> activeSessions =
          List<ActiveSession>.from(_snapshot.activeSessions)..removeAt(index);
      final List<SessionRecord> history =
          List<SessionRecord>.from(_snapshot.history)..add(record);
      _snapshot = AppSnapshot(
        settings: _snapshot.settings,
        devices: _snapshot.devices,
        activeSessions: activeSessions,
        history: history,
        nextSessionNumber: _snapshot.nextSessionNumber,
        nextNotificationId: _snapshot.nextNotificationId,
      );
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _resyncExpiredNotifications() async {
    final List<ActiveSession> pendingSessions =
        List<ActiveSession>.from(_snapshot.activeSessions);
    for (final ActiveSession session in pendingSessions) {
      if (session.kind == SessionKind.fixed && session.plannedEndAt != null) {
        final DateTime now = DateTime.now();
        if (now.isBefore(session.plannedEndAt!)) {
          if (session.notificationId != null) {
            await _notifications.cancelNotification(session.notificationId!);
            await _notifications.scheduleSessionAlert(
              notificationId: session.notificationId!,
              title: 'PS4 Timer Manager',
              body: settings.language == AppLanguage.ar
                  ? 'انتهى وقت ${session.deviceName}'
                  : 'Time is up for ${session.deviceName}',
              deviceName: session.deviceName,
              scheduledAt: session.plannedEndAt!,
              soundUri: settings.customRingtoneUri,
            );
          }
        } else {
          await stopSession(session.id);
        }
      }
    }
  }

  Future<bool> requestNotificationPermission() =>
      _notifications.requestNotificationPermission();

  Future<bool> requestExactAlarmPermission() =>
      _notifications.requestExactAlarmPermission();

  double calculateAmount(Duration duration) {
    final double hours = duration.inSeconds / 3600.0;
    return double.parse((hours * settings.hourlyRate).toStringAsFixed(2));
  }

  String _deviceTitle(DeviceModel device) =>
      device.customName ?? _nextDeviceLabel(device.number);

  String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // تم تعديل الدالة لإزالة الكسور وإضافة رمز العملة حسب لغة التطبيق
  String formatMoney(double amount) {
    final String currency = settings.language == AppLanguage.en ? 'YER' : 'ر.ي';
    return '${amount.toStringAsFixed(0)} $currency';
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.addDevice,
            onPressed: () => _showAddDevicesDialog(context),
            icon: const Icon(Icons.add_business_outlined),
          ),
          IconButton(
            tooltip: l10n.startSession,
            onPressed: controller.devices.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const NewSessionScreen()),
                    ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, _) {
          if (!controller.initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null &&
              controller.devices.isEmpty &&
              controller.history.isEmpty) {
            return _ErrorState(
                onRetry: controller.retryInitialization,
                message: controller.errorMessage!);
          }
          return IndexedStack(
            index: _index,
            children: const <Widget>[
              DevicesScreen(),
              ActiveSessionsScreen(),
              HistoryScreen(),
              SettingsScreen(),
            ],
          );
        },
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: controller.devices.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const NewSessionScreen()),
                      ),
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: Text(l10n.newSession),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          NavigationDestination(
              icon: const Icon(Icons.view_module_outlined),
              label: l10n.devices),
          NavigationDestination(
              icon: const Icon(Icons.schedule_outlined),
              label: l10n.activeSessions),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              label: l10n.history),
          NavigationDestination(
              icon: const Icon(Icons.tune_rounded), label: l10n.settings),
        ],
      ),
    );
  }

  Future<void> _showAddDevicesDialog(BuildContext context) async {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController countController =
        TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addDevices),
          content: TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: l10n.deviceCount, hintText: l10n.addManyHint),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final int count =
                    int.tryParse(countController.text.trim()) ?? 0;
                if (count > 0) {
                  Navigator.pop(context);
                  await controller.addDevices(count);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime now = DateTime.now();

    if (controller.devices.isEmpty) {
      return _EmptyState(
        icon: Icons.sports_esports_rounded,
        title: l10n.noDevicesYet,
        actionLabel: l10n.addDevices,
        onAction: () async {
          await controller.addDevices(1);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.retryInitialization();
      },
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _SummaryHeader(now: now),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 270,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final DeviceModel device = controller.devices[index];
                  final ActiveSession? session =
                      controller.activeSessionForDevice(device.id);
                  return DeviceCard(
                    device: device,
                    session: session,
                    now: now,
                    onTap: () => _openDeviceActions(context, device, session),
                    onLongPress: () =>
                        _confirmDeleteDevice(context, device, session),
                  );
                },
                childCount: controller.devices.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeviceActions(
    BuildContext context,
    DeviceModel device,
    ActiveSession? session,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (session == null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NewSessionScreen(prefilledDeviceId: device.id),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final AppController controller = AppScope.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                device.customName ?? l10n.deviceLabel(device.number),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                  '${l10n.customer}: ${session.customerName.isEmpty ? '-' : session.customerName}'),
              const SizedBox(height: 4),
              Text(
                  '${l10n.sessionType}: ${l10n.sessionTypeLabel(session.kind)}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.stopSession(session.id);
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.stopSession),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteDevice(
    BuildContext context,
    DeviceModel device,
    ActiveSession? session,
  ) async {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (session != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotDeleteBusyDevice)),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteDevice),
          content: Text(
              '${l10n.confirmDeleteDevice} ${device.customName ?? l10n.deviceLabel(device.number)}؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await controller.deleteDevice(device.id);
    }
  }
}

class ActiveSessionsScreen extends StatelessWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (controller.activeSessions.isEmpty) {
      return _EmptyState(
        icon: Icons.schedule_outlined,
        title: l10n.noActiveSessions,
        actionLabel: l10n.newSession,
        onAction: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewSessionScreen()),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.activeSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final ActiveSession session = controller.activeSessions[index];
        return _ActiveSessionCard(session: session);
      },
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateFormat format = DateFormat(
        'yyyy/MM/dd HH:mm', Localizations.localeOf(context).languageCode);

    if (controller.history.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.noHistoryYet,
        actionLabel: l10n.addDevices,
        onAction: () async => controller.addDevices(1),
      );
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _ReportsCard(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final SessionRecord record = controller.history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            record.deviceName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '${l10n.customer}: ${record.customerName.isEmpty ? '-' : record.customerName}'),
                          const SizedBox(height: 4),
                          Text(
                              '${l10n.startAt}: ${format.format(record.startedAt)}'),
                          Text(
                              '${l10n.endAt}: ${format.format(record.endedAt)}'),
                          Text(
                              '${l10n.sessionDuration}: ${AppScope.of(context).formatDuration(Duration(seconds: record.durationSeconds))}'),
                          Text(
                              '${l10n.amountDue}: ${AppScope.of(context).formatMoney(record.amountPaid)}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: controller.history.length,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SettingsSection(
          title: l10n.language,
          subtitle: l10n.languageSettingHint,
          child: DropdownButtonFormField<AppLanguage>(
            value: controller.settings.language,
            items: AppLanguage.values
                .map(
                  (AppLanguage language) => DropdownMenuItem<AppLanguage>(
                    value: language,
                    child: Text(l10n.languageName(language)),
                  ),
                )
                .toList(),
            onChanged: (AppLanguage? value) {
              if (value != null) {
                controller.updateSettings(
                    controller.settings.copyWith(language: value));
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.theme,
          subtitle: l10n.themeSettingHint,
          child: DropdownButtonFormField<AppThemeMode>(
            value: controller.settings.themeMode,
            items: AppThemeMode.values
                .map(
                  (AppThemeMode mode) => DropdownMenuItem<AppThemeMode>(
                    value: mode,
                    child: Text(l10n.themeName(mode)),
                  ),
                )
                .toList(),
            onChanged: (AppThemeMode? value) {
              if (value != null) {
                controller.updateSettings(
                    controller.settings.copyWith(themeMode: value));
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.hourlyRate,
          // تم إضافة رمز العملة للتوضيح في شاشة الإعدادات
          subtitle: '${l10n.pricePerHour} (${l10n.yer})',
          child: TextFormField(
            initialValue: controller.settings.hourlyRate.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (String value) {
              final double rate = double.tryParse(value.trim()) ??
                  controller.settings.hourlyRate;
              controller.updateSettings(
                  controller.settings.copyWith(hourlyRate: rate));
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.defaultFixedDuration,
          subtitle: l10n.durationMinutes,
          child: TextFormField(
            initialValue: controller.settings.defaultFixedMinutes.toString(),
            keyboardType: TextInputType.number,
            onFieldSubmitted: (String value) {
              final int minutes = int.tryParse(value.trim()) ??
                  controller.settings.defaultFixedMinutes;
              controller.updateSettings(
                  controller.settings.copyWith(defaultFixedMinutes: minutes));
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.requestNotifications,
          subtitle: l10n.requestNotifications,
          child: FilledButton(
            onPressed: () async {
              final bool granted =
                  await controller.requestNotificationPermission();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(granted
                          ? l10n.permissionGranted
                          : l10n.permissionDenied)),
                );
              }
            },
            child: Text(l10n.requestNotifications),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.requestExactAlarms,
          subtitle: l10n.requestExactAlarms,
          child: FilledButton.tonal(
            onPressed: () async {
              final bool granted =
                  await controller.requestExactAlarmPermission();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(granted
                          ? l10n.permissionGranted
                          : l10n.permissionDenied)),
                );
              }
            },
            child: Text(l10n.requestExactAlarms),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.changeRingtone,
          subtitle: l10n.pickRingtoneHint,
          child: FilledButton.tonalIcon(
            onPressed: () => controller.pickRingtone(),
            icon: const Icon(Icons.music_note_rounded),
            label: Text(l10n.changeRingtone),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          title: l10n.addDevices,
          subtitle: l10n.addManyHint,
          child: FilledButton.icon(
            onPressed: () async {
              await controller.addDevices(1);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deviceAddedSuccess)),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addDevice),
          ),
        ),
      ],
    );
  }
}

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key, this.prefilledDeviceId});

  final String? prefilledDeviceId;

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  SessionKind _kind = SessionKind.open;
  String? _selectedDeviceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppController controller = AppScope.of(context);
    if (_selectedDeviceId == null) {
      _selectedDeviceId = widget.prefilledDeviceId ??
          (controller.devices.isEmpty ? null : controller.devices.first.id);
      _minutesController.text =
          controller.settings.defaultFixedMinutes.toString();
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newSession)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SessionModeCard(
            kind: _kind,
            onChanged: (SessionKind value) => setState(() => _kind = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDeviceId,
            decoration: InputDecoration(labelText: l10n.deviceName),
            items: controller.devices
                .map(
                  (DeviceModel device) => DropdownMenuItem<String>(
                    value: device.id,
                    child: Text(
                        device.customName ?? l10n.deviceLabel(device.number)),
                  ),
                )
                .toList(),
            onChanged: (String? value) =>
                setState(() => _selectedDeviceId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerController,
            decoration: InputDecoration(labelText: l10n.customerNameOptional),
          ),
          const SizedBox(height: 12),
          if (_kind == SessionKind.fixed) ...<Widget>[
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.durationMinutes),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final int minutes in <int>[30, 60, 120])
                  ActionChip(
                    label: Text('$minutes ${l10n.minutes}'),
                    onPressed: () => setState(
                        () => _minutesController.text = minutes.toString()),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _selectedDeviceId == null
                ? null
                : () async {
                    final int fixedMinutes =
                        int.tryParse(_minutesController.text.trim()) ??
                            controller.settings.defaultFixedMinutes;
                    await controller.startSession(
                      deviceId: _selectedDeviceId!,
                      kind: _kind,
                      customerName: _customerController.text.trim(),
                      fixedMinutes: fixedMinutes,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(l10n.startSession),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.session,
    required this.now,
    required this.onTap,
    this.onLongPress,
  });

  final DeviceModel device;
  final ActiveSession? session;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool busy = session != null;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color statusColor = busy ? colorScheme.error : colorScheme.primary;
    final Color backgroundColor = busy
        ? colorScheme.errorContainer.withValues(alpha: 0.6)
        : colorScheme.secondaryContainer.withValues(alpha: 0.4);

    final Duration displayDuration = busy
        ? (session!.kind == SessionKind.fixed
            ? (session!.remainingAt(now) ?? Duration.zero)
            : session!.elapsedAt(now))
        : Duration.zero;

    final String subtitle = busy
        ? session!.kind == SessionKind.fixed
            ? '${l10n.remainingTime}: ${controller.formatDuration(displayDuration)}'
            : '${l10n.usedTime}: ${controller.formatDuration(displayDuration)}'
        : l10n.available;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: const Color(0xFF607D8B).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF607D8B).withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    busy
                        ? Icons.lock_clock_rounded
                        : Icons.check_circle_outline_rounded,
                    color: statusColor,
                    size: 26,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                device.customName ?? l10n.deviceLabel(device.number),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (busy) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '${l10n.customer}: ${session!.customerName.isEmpty ? '-' : session!.customerName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${l10n.sessionType}: ${l10n.sessionTypeLabel(session!.kind)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.amountDue}: ${controller.formatMoney(controller.calculateAmount(session!.elapsedAt(now)))}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});

  final ActiveSession session;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime now = DateTime.now();
    final Duration duration = session.kind == SessionKind.fixed
        ? (session.remainingAt(now) ?? Duration.zero)
        : session.elapsedAt(now);
    final bool expired = session.kind == SessionKind.fixed && session.isExpired;
    final double currentAmount =
        controller.calculateAmount(session.elapsedAt(now));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    session.deviceName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(expired
                      ? '00:00:00'
                      : controller.formatDuration(duration)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                '${l10n.customer}: ${session.customerName.isEmpty ? '-' : session.customerName}'),
            Text('${l10n.sessionType}: ${l10n.sessionTypeLabel(session.kind)}'),
            Text(
              '${l10n.amountDue}: ${controller.formatMoney(currentAmount)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
            Text(expired
                ? '${l10n.deviceEndedMessage} ${session.deviceNumber}'
                : l10n.currentSession),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: session.kind == SessionKind.fixed
                        ? () async {
                            await _extendSession(context, session);
                          }
                        : null,
                    icon: const Icon(Icons.add_alarm_rounded),
                    label: Text(l10n.extendTime),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await controller.stopSession(session.id);
                    },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l10n.stopSession),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extendSession(
      BuildContext context, ActiveSession session) async {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controllerMinutes =
        TextEditingController(text: '30');
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.extendTime),
          content: TextField(
            controller: controllerMinutes,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: '${l10n.extendBy} ${l10n.minutes}'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final int minutes =
                    int.tryParse(controllerMinutes.text.trim()) ?? 0;
                Navigator.pop(context);
                await controller.extendSession(
                    sessionId: session.id, minutes: minutes);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double revenue = controller.history.fold<double>(
        0, (double sum, SessionRecord item) => sum + item.amountPaid);
    final int active = controller.activeSessions.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0E7490), Color(0xFF134E5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.appTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _SummaryPill(
                  label: l10n.totalDevices,
                  value: controller.devices.length.toString()),
              _SummaryPill(label: l10n.activeNow, value: active.toString()),
              _SummaryPill(
                  label: l10n.totalSessions,
                  value: controller.history.length.toString()),
              _SummaryPill(
                  label: l10n.totalRevenue,
                  value: controller.formatMoney(revenue)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SessionModeCard extends StatelessWidget {
  const _SessionModeCard({required this.kind, required this.onChanged});

  final SessionKind kind;
  final ValueChanged<SessionKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SegmentedButton<SessionKind>(
      segments: <ButtonSegment<SessionKind>>[
        ButtonSegment<SessionKind>(
            value: SessionKind.open,
            label: Text(l10n.openSession),
            icon: const Icon(Icons.timer_outlined)),
        ButtonSegment<SessionKind>(
            value: SessionKind.fixed,
            label: Text(l10n.fixedSession),
            icon: const Icon(Icons.timer_rounded)),
      ],
      selected: <SessionKind>{kind},
      onSelectionChanged: (Set<SessionKind> selected) =>
          onChanged(selected.first),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double revenue = controller.history.fold<double>(
        0, (double sum, SessionRecord item) => sum + item.amountPaid);
    final Duration totalDuration = controller.history.fold<Duration>(
        Duration.zero,
        (Duration sum, SessionRecord item) =>
            sum + Duration(seconds: item.durationSeconds));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.reports, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${l10n.totalSessions}: ${controller.history.length}'),
          Text('${l10n.totalRevenue}: ${controller.formatMoney(revenue)}'),
          Text(
              '${l10n.sessionDuration}: ${controller.formatDuration(totalDuration)}'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.actionLabel,
      required this.onAction});

  final IconData icon;
  final String title;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});

  final Future<void> Function() onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).retry)),
          ],
        ),
      ),
    );
  }
}
