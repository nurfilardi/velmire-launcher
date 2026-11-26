import 'dart:io';

import 'package:flutter/foundation.dart';

class AppLog {
  static const _maxLines = 300;
  static const _maxBytes = 128 * 1024;
  static final List<String> _lines = [];
  static File? _file;

  static String get path => _file?.path ?? '';

  static List<String> get lines => List.unmodifiable(_lines);

  static void init() {
    try {
      _file = File('${Directory.systemTemp.path}/velmire.log');
      if (_file!.existsSync() && _file!.lengthSync() > _maxBytes) {
        _file!.writeAsStringSync('');
      }
    } catch (_) {
      _file = null;
    }
  }

  static void log(String message) {
    final line = '${DateTime.now().toIso8601String()} $message';
    _lines.add(line);
    if (_lines.length > _maxLines) _lines.removeAt(0);
    debugPrint('[velmire] $message');
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  static void exception(String where, Object error, [StackTrace? stack]) {
    log('$where: $error');
    if (stack != null) log(stack.toString());
  }
}
