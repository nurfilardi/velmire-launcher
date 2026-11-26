import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

import 'ini_writer.dart';

class DataStatus {
  final bool folderExists;
  final bool texdbExists;
  final int bytes;
  final int files;

  const DataStatus({
    required this.folderExists,
    required this.texdbExists,
    required this.bytes,
    required this.files,
  });

  static const minReadyBytes = 500 * 1024 * 1024;
  bool get ready => folderExists && texdbExists && bytes > minReadyBytes;
}

class DownloadProgress {
  final int received;
  final int total;
  final bool done;
  final String path;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.done,
    required this.path,
  });

  double get ratio => total > 0 ? (received / total).clamp(0, 1) : 0;
}

class UnsupportedArchive implements Exception {
  final String message;
  const UnsupportedArchive(this.message);
  @override
  String toString() => message;
}

class GameData {
  final String cachePath;
  final http.Client _client;

  GameData(this.cachePath, {http.Client? client}) : _client = client ?? http.Client();

  Directory get root => Directory(cachePath);
  Directory get _downloads => Directory('$cachePath/.downloads');

  Future<DataStatus> status() async {
    final dir = root;
    if (!await dir.exists()) {
      return const DataStatus(folderExists: false, texdbExists: false, bytes: 0, files: 0);
    }
    var bytes = 0;
    var files = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files++;
        try {
          bytes += await entity.length();
        } catch (_) {}
      }
    }
    return DataStatus(
      folderExists: true,
      texdbExists: await Directory('$cachePath/texdb').exists(),
      bytes: bytes,
      files: files,
    );
  }

  Stream<DownloadProgress> download(String url, {required bool lite}) async* {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const FormatException('URL harus http/https langsung ke file');
    }
    if (uri.path.toLowerCase().endsWith('.7z')) {
      throw const UnsupportedArchive('File .7z belum didukung. Pakai .zip.');
    }
    await _downloads.create(recursive: true);
    final target = '$cachePath/.downloads/${lite ? 'lite' : 'full'}.zip';
    final part = File('$target.part');
    var existing = await part.exists() ? await part.length() : 0;

    final request = http.Request('GET', uri);
    if (existing > 0) request.headers['Range'] = 'bytes=$existing-';
    final response = await _client.send(request).timeout(const Duration(seconds: 30));

    var mode = FileMode.append;
    var total = existing + (response.contentLength ?? 0);
    if (response.statusCode == 206) {
      final range = response.headers['content-range'];
      final match = range == null ? null : RegExp(r'/(\d+)$').firstMatch(range);
      if (match != null) total = int.parse(match.group(1)!);
    } else if (response.statusCode == 200) {
      existing = 0;
      mode = FileMode.write;
      total = response.contentLength ?? 0;
    } else {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }

    final sink = part.openWrite(mode: mode);
    var received = existing;
    yield DownloadProgress(received: received, total: total, done: false, path: target);
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(received: received, total: total, done: false, path: target);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    final file = await part.rename(target);
    yield DownloadProgress(
      received: received,
      total: total > 0 ? total : received,
      done: true,
      path: file.path,
    );
  }

  Future<void> importArchive(String sourcePath) async {
    final name = sourcePath.toLowerCase();
    if (name.endsWith('.7z') || name.endsWith('.rar')) {
      throw const UnsupportedArchive('Format ini belum didukung. Pakai .zip.');
    }
    await _downloads.create(recursive: true);
    final dest = '$cachePath/.downloads/import.zip';
    await File(sourcePath).copy(dest);
    await extract(dest);
  }

  Future<void> extract(String zipPath) async {
    final input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(input);
    final files = archive.files.where((f) => f.isFile).toList(growable: false);
    final stripGta = files.isNotEmpty &&
        files.every((f) {
          final segs = _segments(f.name);
          return segs.isNotEmpty && segs.first.toLowerCase() == 'gta';
        });
    await root.create(recursive: true);
    try {
      for (final entry in archive.files) {
        if (!entry.isFile || entry.isSymbolicLink) continue;
        final rel = _safePath(entry.name, stripGta: stripGta);
        if (rel == null) continue;
        final destination = File('$cachePath/$rel');
        await destination.parent.create(recursive: true);
        final temp = File('${destination.path}.tmp');
        final out = OutputFileStream(temp.path);
        try {
          entry.writeContent(out);
          await out.close();
        } catch (_) {
          await out.close();
          rethrow;
        }
        await temp.rename(destination.path);
      }
    } finally {
      await input.close();
      if (zipPath.startsWith('$cachePath/.downloads')) {
        try {
          await File(zipPath).delete();
        } catch (_) {}
      }
    }
  }

  Future<void> saveClient({
    required String name,
    required String host,
    required int port,
    String password = '',
  }) async {
    final dir = Directory('$cachePath/SAMP');
    await dir.create(recursive: true);
    final file = File('${dir.path}/settings.ini');
    final backup = File('${dir.path}/settings.ini.bak');
    var content = '';
    if (await file.exists()) {
      content = await file.readAsString();
      if (!await backup.exists()) await file.copy(backup.path);
    }
    final updated = upsertClientSection(
      content,
      name: name,
      host: host,
      port: port,
      password: password,
    );
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(updated, flush: true);
    await temp.rename(file.path);
  }

  Future<void> deleteData() async {
    if (await root.exists()) await root.delete(recursive: true);
  }

  List<String> _segments(String raw) =>
      raw.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();

  String? _safePath(String raw, {required bool stripGta}) {
    var normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
      return null;
    }
    final segments = _segments(normalized);
    if (segments.any((s) => s == '..' || s == '.')) return null;
    if (stripGta && segments.isNotEmpty && segments.first.toLowerCase() == 'gta') {
      segments.removeAt(0);
    }
    if (segments.isEmpty) return null;
    return segments.join('/');
  }
}

String formatBytes(int bytes) {
  if (bytes >= 1 << 30) return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
  if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
  if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String prettyJson(Object value) => const JsonEncoder.withIndent('  ').convert(value);
