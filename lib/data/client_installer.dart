import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../platform/native_bridge.dart';
import 'resource_manifest.dart';

class ClientDownload {
  final int received;
  final int total;

  const ClientDownload(this.received, this.total);

  double get ratio => total > 0 ? (received / total).clamp(0, 1) : 0;
}

class ClientInstaller {
  final NativeBridge bridge;
  final http.Client _client;

  ClientInstaller({NativeBridge? bridge, http.Client? client})
    : bridge = bridge ?? NativeBridge(),
      _client = client ?? http.Client();

  Future<File> download(
    ClientPackage package, {
    void Function(ClientDownload progress)? onProgress,
  }) async {
    final uri = Uri.tryParse(package.url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const FormatException('URL client harus http/https');
    }
    final dir = Directory('${Directory.systemTemp.path}/velmire-client');
    await dir.create(recursive: true);
    final target = File('${dir.path}/client.apk');
    final part = File('${target.path}.part');
    if (await part.exists()) await part.delete();

    final response = await _client
        .send(http.Request('GET', uri))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final total = response.contentLength ?? package.size;
    if (package.size > 0 && total > package.size) {
      throw Exception('Ukuran client melebihi manifest');
    }
    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (package.size > 0 && received > package.size) {
          throw Exception('Ukuran client melebihi manifest');
        }
        sink.add(chunk);
        onProgress?.call(ClientDownload(received, total));
      }
      await sink.flush();
    } catch (_) {
      try {
        await part.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await sink.close();
    }
    if (package.checksum.isNotEmpty) {
      final actual = (await sha256.bind(part.openRead()).first).toString();
      if (actual.toLowerCase() != package.checksum.toLowerCase()) {
        await part.delete();
        throw Exception('Checksum client tidak cocok');
      }
    }
    return part.rename(target.path);
  }

  Future<bool> install(File apk) => bridge.installApk(apk.path);
}
