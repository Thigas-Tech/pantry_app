import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/services/github_issue_service.dart';
import 'package:pantry_app/services/image_cache_service.dart';

/// Guards the single dependency-injection path for [DatabaseHelper] and
/// [ImageCacheService].
///
/// Both services are singletons exposed through providers
/// ([databaseProvider] / [imageCacheProvider]). Production code must
/// consume them via the container, not by constructing them directly —
/// otherwise tests cannot override a single instance and the app ends up
/// with two DI paths for the same singleton.
///
/// Allowed direct construction:
/// - the owning provider files (the provider body itself),
/// - [DatabaseHelper]'s own factory definition,
/// - [GithubIssueService]'s constructor default
///   (`databaseHelper ?? DatabaseHelper()`), which is a legitimate
///   dependency-injection fallback.
void main() {
  final bannedConstructors = <RegExp, (String, List<String>)>{
    RegExp(r'DatabaseHelper\((?!\{)'): (
      'must be provided via databaseProvider',
      <String>[
        'database_helper.dart',
        'database_provider.dart',
        'github_issue_service.dart',
      ],
    ),
    RegExp(r'ImageCacheService\((?!\{)'): (
      'must be provided via imageCacheProvider',
      <String>[
        'image_cache_service.dart',
        'image_cache_provider.dart',
      ],
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
