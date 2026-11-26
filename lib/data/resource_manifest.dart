import 'dart:convert';

import 'package:http/http.dart' as http;

final _sha256 = RegExp(r'^[0-9a-fA-F]{64}$');

class ResourceSource {
  final String name;
  final String url;
  final int size;
  final String checksum;
  final String description;

  const ResourceSource({
    required this.name,
    required this.url,
    this.size = 0,
    this.checksum = '',
    this.description = '',
  });

  bool get valid {
    final uri = Uri.tryParse(url);
    return name.trim().isNotEmpty &&
        uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        size >= 0 &&
        (checksum.isEmpty || _sha256.hasMatch(checksum));
  }

  factory ResourceSource.fromJson(Map<String, dynamic> json) => ResourceSource(
    name: (json['name'] ?? '').toString().trim(),
    url: (json['url'] ?? '').toString().trim(),
    size: _int(json['size']),
    checksum: (json['checksum'] ?? '').toString().trim(),
    description: (json['description'] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'size': size,
    'checksum': checksum,
    'description': description,
  };

  static int _int(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}

class ClientPackage {
  final String name;
  final String url;
  final int size;
  final String checksum;

  const ClientPackage({
    required this.name,
    required this.url,
    this.size = 0,
    this.checksum = '',
  });

  bool get valid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        (checksum.isEmpty || _sha256.hasMatch(checksum));
  }

  factory ClientPackage.fromJson(Map<String, dynamic> json) => ClientPackage(
    name: (json['name'] ?? 'Client').toString(),
    url: (json['url'] ?? '').toString().trim(),
    size: ResourceSource._int(json['size']),
    checksum: (json['checksum'] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'size': size,
    'checksum': checksum,
  };
}

class ResourceManifest {
  final List<ResourceSource> sources;
  final ClientPackage? client;

  const ResourceManifest({this.sources = const [], this.client});

  factory ResourceManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['sources'];
    final list = raw is List ? raw : const [];
    final sources = list
        .whereType<Map>()
        .map((e) => ResourceSource.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.valid)
        .toList(growable: false);
    final rawClient = json['client'];
    final client = rawClient is Map
        ? ClientPackage.fromJson(Map<String, dynamic>.from(rawClient))
        : null;
    return ResourceManifest(
      sources: sources,
      client: client != null && client.valid ? client : null,
    );
  }

  static ResourceManifest parse(String text) {
    final value = jsonDecode(text);
    if (value is! Map) throw const FormatException('Manifest harus objek JSON');
    return ResourceManifest.fromJson(Map<String, dynamic>.from(value));
  }

  Map<String, dynamic> toJson() => {
    'sources': sources.map((s) => s.toJson()).toList(),
    if (client != null) 'client': client!.toJson(),
  };

  static Future<ResourceManifest> fetch(
    http.Client client,
    String url, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw const FormatException('URL manifest harus http/https');
    }
    final response = await client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    if (response.bodyBytes.length > 1024 * 1024) {
      throw const FormatException('Manifest terlalu besar');
    }
    return parse(utf8.decode(response.bodyBytes));
  }
}

class HttpException implements Exception {
  final String message;
  final Uri? uri;
  const HttpException(this.message, {this.uri});
  @override
  String toString() => 'HTTP $message';
}
