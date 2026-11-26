import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/game_data.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('samp_cache_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  List<int> buildZip(Map<String, String> files) {
    final archive = Archive();
    files.forEach((name, content) {
      final bytes = content.codeUnits;
      archive.addFile(ArchiveFile.bytes(name, bytes));
    });
    return ZipEncoder().encode(archive);
  }

  test('extracts and strips top-level GTA folder', () async {
    final cache = Directory('${temp.path}/GTA')..createSync(recursive: true);
    final zip = File('${temp.path}/data.zip');
    await zip.writeAsBytes(buildZip({
      'GTA/texdb/a.txt': 'hello',
      'GTA/SAMP/settings.ini': '[client]\nname = x\n',
    }));

    final data = GameData(cache.path);
    await data.extract(zip.path);

    expect(File('${cache.path}/texdb/a.txt').readAsStringSync(), 'hello');
    expect(File('${cache.path}/SAMP/settings.ini').existsSync(), isTrue);
  });

  test('never writes outside cache on hostile paths', () async {
    final cache = Directory('${temp.path}/GTA')..createSync(recursive: true);
    final zip = File('${temp.path}/evil.zip');
    await zip.writeAsBytes(buildZip({
      '../evil.txt': 'nope',
      '/absolute.txt': 'nope',
      'texdb/ok.txt': 'yes',
    }));

    final data = GameData(cache.path);
    await data.extract(zip.path);

    expect(File('${temp.path}/evil.txt').existsSync(), isFalse);
    expect(File('${temp.path}/absolute.txt').existsSync(), isFalse);
    expect(File('${cache.path}/texdb/ok.txt').readAsStringSync(), 'yes');
  });

  test('writes client settings with backup', () async {
    final cache = Directory('${temp.path}/GTA')..createSync(recursive: true);
    final data = GameData(cache.path);

    await data.saveClient(name: 'A', host: 'h', port: 7777);
    final file = File('${cache.path}/SAMP/settings.ini');
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), contains('name = A'));

    await data.saveClient(name: 'B', host: 'h', port: 7777);
    expect(file.readAsStringSync(), contains('name = B'));
    expect(File('${cache.path}/SAMP/settings.ini.bak').existsSync(), isTrue);
  });

  test('unsupported archive extension is rejected', () async {
    final file = File('${temp.path}/data.7z');
    await file.writeAsBytes([1, 2, 3]);
    final data = GameData('${temp.path}/GTA');
    expect(() => data.importArchive(file.path), throwsA(isA<UnsupportedArchive>()));
  });
}
