import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:samp_launcher/data/server_repository.dart';
import 'package:samp_launcher/models/server.dart';

void main() {
  test('parses api list and dedupes manual first', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response(
        jsonEncode([
          {'ipAddress': '1.1.1.1', 'port': 7777, 'hostname': 'Api One', 'onlinePlayers': 5, 'maxplayers': 10},
          {'ipAddress': '2.2.2.2', 'port': 7777, 'hostname': 'Api Two', 'onlinePlayers': 1, 'maxplayers': 10},
        ]),
        200,
      );
    });
    final repo = ServerRepository(client);
    final api = await repo.fetchApi();
    expect(api.length, 2);

    final merged = ServerRepository.mergeManual(api, [
      const Server(host: '2.2.2.2', port: 7777, name: 'Manual Two', manual: true),
    ]);
    expect(merged.length, 2);
    expect(merged.first.name, 'Manual Two');
    expect(merged.first.manual, isTrue);

    await repo.fetchApi();
    expect(calls, 1, reason: 'cache 60s');
  });

  test('keeps last good list when request fails', () async {
    var fail = false;
    final client = MockClient((req) async {
      if (fail) return http.Response('oops', 500);
      return http.Response(
        jsonEncode([
          {'ipAddress': '1.1.1.1', 'port': 7777, 'hostname': 'Api One'},
        ]),
        200,
      );
    });
    final repo = ServerRepository(client);
    expect((await repo.fetchApi()).length, 1);
    fail = true;
    final cached = await repo.fetchApi(force: true);
    expect(cached.length, 1);
  });
}
