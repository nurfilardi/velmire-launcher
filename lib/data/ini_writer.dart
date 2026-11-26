final _section = RegExp(r'^\s*\[');
final _key = RegExp(r'^\s*([A-Za-z0-9_.-]+)\s*=');

String _clean(String value) {
  final flat = value.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
  if (flat.length > 1 && flat.startsWith('"') && flat.endsWith('"')) {
    return flat.substring(1, flat.length - 1);
  }
  return flat;
}

/// Updates the `[client]` section while keeping every other line.
String upsertClientSection(
  String content, {
  required String name,
  required String host,
  required int port,
  String password = '',
}) {
  final lines = content.replaceAll('\r\n', '\n').split('\n');
  final values = <String, String>{
    'name': _clean(name),
    'host': _clean(host),
    'port': '$port',
    'password': _clean(password),
  };
  final start = lines.indexWhere((l) => l.trim().toLowerCase() == '[client]');
  if (start == -1) {
    if (lines.isNotEmpty && lines.last.trim().isNotEmpty) lines.add('');
    lines.add('[client]');
    values.forEach((k, v) => lines.add('$k = $v'));
    return lines.join('\n');
  }

  var end = lines.length;
  for (var i = start + 1; i < lines.length; i++) {
    if (_section.hasMatch(lines[i])) {
      end = i;
      break;
    }
  }

  final remaining = values.keys.toSet();
  for (var i = start + 1; i < end; i++) {
    final match = _key.firstMatch(lines[i]);
    if (match == null) continue;
    final key = match.group(1)!.toLowerCase();
    if (values.containsKey(key)) {
      lines[i] = '$key = ${values[key]}';
      remaining.remove(key);
    }
  }
  var insertAt = start + 1;
  for (final key in values.keys) {
    if (remaining.contains(key)) {
      lines.insert(insertAt++, '$key = ${values[key]}');
    }
  }
  return lines.join('\n');
}
