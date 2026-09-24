import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards against duplicate singleton service construction in providers.
///
/// [CurrencyService] must be created exactly once each,
/// currency_service_provider.dart). Other layers must consume them via
/// currencyServiceProvider so tests can override
/// a single instance and no client instances are silently duplicated.
///
/// The scan mirrors test/database/sqlite_compatibility_test.dart: it
/// checks the production source tree and fails if a direct constructor call
/// is reintroduced outside the allowlist.
void main() {
  setUpAll(() {
    dotenv.loadFromString(isOptional: true, mergeWith: {});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final bannedConstructors = <RegExp, (String, List<String>)>{
    // The negative lookahead excludes the class's own constructor
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
