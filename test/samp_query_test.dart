import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/samp_query.dart';

Uint8List _infoPacket({
  required String hostname,
  required String gamemode,
  required String language,
  int players = 3,
  int maxPlayers = 50,
  bool passworded = false,
}) {
  final strings = [hostname, gamemode, language];
  final buffer = BytesBuilder();
  buffer.add([0x53, 0x41, 0x4D, 0x50]);
  buffer.add([1, 2, 3, 4]);
  buffer.add([0x61, 0x1F]); // 7777 little endian
  buffer.addByte(0x69);
  buffer.addByte(passworded ? 1 : 0);
  final header = ByteData(4);
  header.setUint16(0, players, Endian.little);
  header.setUint16(2, maxPlayers, Endian.little);
  buffer.add(header.buffer.asUint8List());
  for (final value in strings) {
    final len = ByteData(4)..setUint32(0, value.length, Endian.little);
    buffer.add(len.buffer.asUint8List());
    buffer.add(value.codeUnits);
  }
  return buffer.toBytes();
}

void main() {
  test('builds SAMP info packet', () {
    final packet = buildInfoPacket('127.0.0.1', 7777);
    expect(packet.sublist(0, 4), [0x53, 0x41, 0x4D, 0x50]);
    expect(packet.sublist(4, 8), [127, 0, 0, 1]);
    expect(packet[8], 0x61);
    expect(packet[9], 0x1E);
    expect(packet[10], 0x69);
  });

  test('rejects invalid host', () {
    expect(() => buildInfoPacket('play.example.id', 7777), throwsFormatException);
    expect(() => buildInfoPacket('999.1.1.1', 7777), throwsFormatException);
  });

  test('parses info response', () {
    final packet = _infoPacket(
      hostname: 'Jogjagamers',
      gamemode: 'JG:RP',
      language: 'Indonesia',
      players: 254,
      maxPlayers: 999,
    );
    final info = parseInfoPacket(packet);
    expect(info, isNotNull);
    expect(info!.hostname, 'Jogjagamers');
    expect(info.gamemode, 'JG:RP');
    expect(info.players, 254);
    expect(info.maxPlayers, 999);
    expect(info.passworded, isFalse);
  });

  test('rejects truncated or wrong packets', () {
    expect(parseInfoPacket(Uint8List.fromList([1, 2, 3])), isNull);
    expect(parseInfoPacket(Uint8List(20)), isNull);
    final ok = _infoPacket(hostname: 'x', gamemode: 'y', language: 'z');
    expect(parseInfoPacket(ok.sublist(0, 20)), isNull);
  });
}
