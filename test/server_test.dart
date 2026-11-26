import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/models/server.dart';

void main() {
  test('maps API json', () {
    final server = Server.fromApi({
      'ipAddress': '31.58.143.109',
      'port': 7777,
      'hostname': ' Vice Side Roleplay ',
      'gamemode': 'VS:RP',
      'language': 'Indonesia',
      'version': 'omp 1.5.8',
      'onlinePlayers': 581,
      'maxplayers': 1000,
      'passworded': 0,
    });
    expect(server.name, 'Vice Side Roleplay');
    expect(server.address, '31.58.143.109:7777');
    expect(server.players, 581);
    expect(server.passworded, isFalse);
    expect(versionFamily(server.version), 'OPENMP');
  });

  test('version families', () {
    expect(versionFamily('0.3.7 R5'), '0.3.7');
    expect(versionFamily('0.3.DL R1'), '0.3.DL');
    expect(versionFamily('open.mp 1.2'), 'OPENMP');
    expect(versionFamily(''), 'LAIN');
  });

  test('manual server round trip', () {
    const server = Server(host: 'play.example.id', port: 7777, name: 'Test', manual: true);
    final copy = Server.fromJson(server.toJson());
    expect(copy.host, server.host);
    expect(copy.port, server.port);
    expect(copy.manual, isTrue);
  });
}
