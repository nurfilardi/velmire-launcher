import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/core/format.dart';
import 'package:samp_launcher/core/validators.dart';

void main() {
  test('format bytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(3 * 1024 * 1024), '3.0 MB');
  });

  test('nick rules', () {
    expect(Validators.nick('Reyzo'), isNull);
    expect(Validators.nick('ab'), isNotNull);
    expect(Validators.nick('a b'), isNotNull);
  });

  test('host and port rules', () {
    expect(Validators.host('31.58.143.109'), isNull);
    expect(Validators.host('https://x'), isNotNull);
    expect(Validators.host(''), isNotNull);
    expect(Validators.port('7777'), isNull);
    expect(Validators.port('0'), isNotNull);
    expect(Validators.port('x'), isNotNull);
  });
}
