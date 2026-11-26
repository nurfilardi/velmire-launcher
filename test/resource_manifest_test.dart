import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:samp_launcher/data/resource_manifest.dart';

void main() {
  test('manifest parses sources and client', () {
    final manifest = ResourceManifest.parse(
      jsonEncode({
        'sources': [
          {
            'name': 'Lite',
            'url': 'https://example.com/lite.zip',
            'size': 100,
            'checksum': 'a' * 64,
            'description': 'test',
          },
          {'name': '', 'url': 'ftp://x', 'size': 1},
        ],
        'client': {
          'name': 'Client',
          'url': 'https://example.com/client.apk',
          'size': 200,
          'checksum': 'b' * 64,
        },
      }),
    );
    expect(manifest.sources, hasLength(1));
    expect(manifest.sources.single.name, 'Lite');
    expect(manifest.client?.name, 'Client');
  });

  test('invalid checksum is rejected', () {
    final manifest = ResourceManifest.parse(
      jsonEncode({
        'sources': [
          {
            'name': 'Bad',
            'url': 'https://example.com/data.zip',
            'checksum': 'xyz',
          },
        ],
      }),
    );
    expect(manifest.sources, isEmpty);
  });

  test('works with empty sources', () {
    expect(ResourceManifest.parse('{"sources":[]}').sources, isEmpty);
  });

  test('picks lite and original sources by name', () {
    final manifest = ResourceManifest.parse(
      jsonEncode({
        'sources': [
          {'name': 'Original HD', 'url': 'https://example.com/full.zip'},
          {'name': 'Lite', 'url': 'https://example.com/lite.zip'},
        ],
      }),
    );
    expect(manifest.sourceFor(DataEdition.lite)?.name, 'Lite');
    expect(manifest.sourceFor(DataEdition.original)?.name, 'Original HD');
  });

  test('missing edition has no source', () {
    final manifest = ResourceManifest.parse(
      jsonEncode({
        'sources': [
          {'name': 'Lite', 'url': 'https://example.com/lite.zip'},
        ],
      }),
    );
    expect(manifest.sourceFor(DataEdition.original), isNull);
  });
}
