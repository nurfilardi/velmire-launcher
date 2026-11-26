import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/ini_writer.dart';

void main() {
  test('creates client section', () {
    final out = upsertClientSection('', name: 'Reyzo', host: '1.2.3.4', port: 7777);
    expect(out, contains('[client]'));
    expect(out, contains('name = Reyzo'));
    expect(out, contains('host = 1.2.3.4'));
    expect(out, contains('port = 7777'));
    expect(out, contains('password = '));
  });

  test('replaces keys and preserves other sections', () {
    const input = '''
[gui]
FontSize = 30.0
snow = false

[client]
name = Old
host = 127.0.0.1
port = 7777
password = secret
version = 0.3.7

[debug]
debug = false
''';
    final out = upsertClientSection(
      input,
      name: 'Budi',
      host: 'play.example.id',
      port: 8888,
      password: '',
    );
    expect(out, contains('name = Budi'));
    expect(out, contains('host = play.example.id'));
    expect(out, contains('port = 8888'));
    expect(out, contains('password = \n'));
    expect(out, contains('version = 0.3.7'), reason: 'unknown keys stay');
    expect(out, contains('FontSize = 30.0'));
    expect(out, contains('[debug]'));
    expect(out, isNot(contains('name = Old')));
  });

  test('adds missing keys and flattens newlines', () {
    const input = '[client]\nname = Old\n';
    final out = upsertClientSection(input, name: 'A\nB', host: 'x', port: 7777);
    expect(out, contains('name = A B'));
    expect(out, contains('host = x'));
  });
}
