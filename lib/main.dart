import 'dart:async';

import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppController controller = AppController();
  runApp(Ps4TimerApp(controller: controller));
  unawaited(controller.initialize());
}
