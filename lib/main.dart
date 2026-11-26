import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'data/config_store.dart';
import 'state/app_state.dart';
import 'ui/crash_view.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLog.init();
    AppLog.log('boot start');
    FlutterError.onError = (details) {
      AppLog.log('flutter error: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };
    ErrorWidget.builder = (details) => CrashView(message: details.exceptionAsString());
    try {
      final prefs = await SharedPreferences.getInstance();
      AppLog.log('prefs ready');
      final state = AppState(store: ConfigStore(prefs));
      state.bootstrap();
      AppLog.log('state ready');
      runApp(SampApp(state: state));
      AppLog.log('runApp called');
    } catch (e, s) {
      AppLog.exception('boot failed', e, s);
      runApp(CrashView(message: '$e'));
    }
  }, (error, stack) {
    AppLog.exception('zone error', error, stack);
    runApp(CrashView(message: '$error'));
  });
}
