import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class ServerInfo {
  final String hostname;
  final String gamemode;
  final String language;
  final int players;
  final int maxPlayers;
  final bool passworded;

  const ServerInfo({
    required this.hostname,
    required this.gamemode,
    required this.language,
    required this.players,
    required this.maxPlayers,
    required this.passworded,
  });
}

const _header = [0x53, 0x41, 0x4D, 0x50];

Uint8List buildInfoPacket(String host, int port) {
  final parts = host.split('.');
  if (parts.length != 4) {
    throw const FormatException('butuh alamat IPv4');
  }
  final bytes = Uint8List(4 + 4 + 2 + 1);
  bytes.setRange(0, 4, _header);
  for (var i = 0; i < 4; i++) {
    final octet = int.tryParse(parts[i]);
    if (octet == null || octet < 0 || octet > 255) {
      throw const FormatException('oktet IPv4 tidak valid');
    }
    bytes[4 + i] = octet;
  }
  final data = ByteData.sublistView(bytes);
  data.setUint16(8, port, Endian.little);
  bytes[10] = 0x69; // 'i'
  return bytes;
}

ServerInfo? parseInfoPacket(Uint8List data) {
  if (data.length < 11) return null;
  for (var i = 0; i < 4; i++) {
    if (data[i] != _header[i]) return null;
  }
  if (data[10] != 0x69) return null;
  final bd = ByteData.sublistView(data);
  try {
    var pos = 11;
    final passworded = data[pos++] != 0;
    final players = bd.getUint16(pos, Endian.little);
    pos += 2;
    final maxPlayers = bd.getUint16(pos, Endian.little);
    pos += 2;
    String readStr() {
      final len = bd.getUint32(pos, Endian.little);
      pos += 4;
      if (pos + len > data.length) throw const FormatException('potong');
      final value = String.fromCharCodes(data.sublist(pos, pos + len));
      pos += len;
      return value;
    }

    final hostname = readStr();
    final gamemode = readStr();
    final language = readStr();
    return ServerInfo(
      hostname: hostname,
      gamemode: gamemode,
      language: language,
      players: players,
      maxPlayers: maxPlayers,
      passworded: passworded,
    );
  } catch (_) {
    return null;
  }
}

Future<ServerInfo?> queryServer(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  RawDatagramSocket? socket;
  try {
    final addresses = await InternetAddress.lookup(host);
    final v4 = addresses.where((a) => a.type == InternetAddressType.IPv4);
    if (v4.isEmpty) return null;
    final target = v4.first;
    final packet = buildInfoPacket(target.address, port);
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final completer = Completer<ServerInfo?>();
    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket?.receive();
      if (datagram == null) return;
      final info = parseInfoPacket(datagram.data);
      if (info != null && !completer.isCompleted) completer.complete(info);
    });
    socket.send(packet, target, port);
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    final result = await completer.future;
    await sub.cancel();
    timer.cancel();
    return result;
  } catch (_) {
    return null;
  } finally {
    socket?.close();
  }
}
