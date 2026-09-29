import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  static const String _fileName = 'ps4_timer_manager_state.json';

  Future<File> _file() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<AppSnapshot> loadSnapshot() async {
    final File file = await _file();
    if (!await file.exists()) {
      return AppSnapshot.defaults();
    }
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return AppSnapshot.defaults();
    }
    return AppSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSnapshot(AppSnapshot snapshot) async {
    final File file = await _file();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
      flush: true,
    );
  }
}
