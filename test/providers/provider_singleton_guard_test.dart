import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/services/usda_api_client.dart';

/// Guards against duplicate singleton service construction in providers.
///
/// [UsdaApiClient] and [CurrencyService] must be created exactly once each,
/// inside their owning provider files (`usda_provider.dart` and
/// `currency_service_provider.dart`). Other layers must consume them via
/// `usdaApiClientProvider` / `currencyServiceProvider` so tests can override
/// a single instance and no client instances are silently duplicated.
///
/// The scan mirrors `test/database/sqlite_compatibility_test.dart`: it
/// checks the production source tree and fails if a direct constructor call
/// is reintroduced outside the allowlist.
void main() {
  final bannedConstructors = <RegExp, (String, List<String>)>{
    // The negative lookahead excludes the class's own constructor
    // declaration, which is written as UsdaApiClient({...}).
    RegExp(r'UsdaApiClient\((?!\{)'): (
      'must be provided via usdaApiClientProvider',
      <String>['usda_provider.dart'],
    ),
    RegExp(r'CurrencyService\((?!\{)'): (
      'must be provided via currencyServiceProvider',
      <String>['currency_service_provider.dart'],
    ),
  };

  for (final entry in bannedConstructors.entries) {
    final pattern = entry.key;
    final (reason, allowedFiles) = entry.value;

    test(
      '$pattern is constructed only inside its provider file',
      () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();
        expect(dartFiles, isNotEmpty);

        final violations = <String>[];
        for (final file in dartFiles) {
          if (allowedFiles.contains(file.uri.pathSegments.last)) continue;
          final content = file.readAsStringSync();
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trimLeft();
            if (line.startsWith('///') || line.startsWith('//')) continue;
            if (pattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1}');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              '$pattern $reason\n'
              'Found direct construction at:\n'
              '${violations.join('\n')}',
        );
      },
    );
  }
}
