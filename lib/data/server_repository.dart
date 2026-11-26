import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/server.dart';

class ServerRepository {
  static const apiUrl = 'https://sa-mp.co.id/api/server.php';
  static const _cacheTtl = Duration(seconds: 60);

  final http.Client _client;
  List<Server> _cache = const [];
  DateTime? _fetchedAt;

  ServerRepository(this._client);

  Future<List<Server>> fetchApi({bool force = false}) async {
    final age = _fetchedAt == null ? null : DateTime.now().difference(_fetchedAt!);
    if (_cache.isNotEmpty && age != null && age < _cacheTtl && !force) {
      return _cache;
    }
    try {
      final res = await _client
          .get(Uri.parse(apiUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List) throw const FormatException('unexpected payload');
      final servers = decoded
          .whereType<Map<String, dynamic>>()
          .map(Server.fromApi)
          .where((s) => s.host.isNotEmpty)
          .toList(growable: false);
      _cache = servers;
      _fetchedAt = DateTime.now();
      return servers;
    } catch (_) {
      if (_cache.isNotEmpty) return _cache;
      rethrow;
    }
  }

  static List<Server> mergeManual(List<Server> api, List<Server> manual) {
    final seen = <String>{};
    final out = <Server>[];
    for (final s in [...manual, ...api]) {
      if (seen.add(s.address)) out.add(s);
    }
    return out;
  }

  void dispose() => _client.close();
}
