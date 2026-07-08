/// A parsed entry from `CHANGELOG.md` representing one version section.
class ChangelogEntry {
  /// Creates a [ChangelogEntry].
  const ChangelogEntry({required this.version, required this.content});

  /// The version string extracted from the `## [...]` header.
  ///
  /// Examples: `'Unreleased'`, `'0.1.0'`, `'1.0.0'`.
  final String version;

  /// The raw body content under this version header.
  ///
  /// Contains everything between this version header and the next (or EOF).
  /// Section grouping (`### Sections`) is handled by the display layer.
  final String content;
}

/// Parses `CHANGELOG.md` into structured [ChangelogEntry] objects.
///
/// The parser splits the raw markdown by `## [version]` headers and extracts
/// version strings and body content. No external markdown library is used.
///
/// ## Markdown format expected
///
///     ## [Unreleased]
///     ### Enhancements
///     - Item 1
///
///     ## [0.1.0] -- Initial release (MVP)
///     ### Core
///     - Item A
class ChangelogParser {
  /// Sentinel value used to sort the Unreleased entry above all
  /// numbered versions.
  static const unreleasedVersion = 'Unreleased';

  /// A [ChangelogEntry] representing the Unreleased section.
  static const unreleased = ChangelogEntry(
    version: unreleasedVersion,
    content: '',
  );

  /// Parses [rawChangelog] into a list of [ChangelogEntry] ordered newest
  /// first (`[Unreleased]` always first, followed by descending semver).
  List<ChangelogEntry> parse(String rawChangelog) {
    if (rawChangelog.isEmpty) {
      return [];
    }

    final entries = <ChangelogEntry>[];
    final sections = rawChangelog.split(RegExp(r'(?:^|\n)## \[(?=[^\[\]]*\])'));
    var isFirst = true;

    for (final section in sections) {
      // The first split element is everything before the first `## [` header
      // (e.g. the `# Changelog` title). Skip it.
      if (isFirst) {
        isFirst = false;
        if (!section.trimLeft().startsWith('[')) {
          continue;
        }
      }

      final headerEnd = section.indexOf(']');
      if (headerEnd == -1) continue;

      final version = section.substring(0, headerEnd).trim();
      if (version.isEmpty) continue;

      // Body content: everything after the header line.
      final bodyStart = section.indexOf('\n');
      final content = bodyStart == -1
          ? ''
          : section.substring(bodyStart + 1).trim();

      // Strip trailing `---` horizontal-rule separators.
      final cleaned = content.replaceAll(RegExp(r'\n---\s*$'), '').trim();

      entries.add(ChangelogEntry(version: version, content: cleaned));
    }

    // Sort: [Unreleased] first, then descending semver.
    entries.sort((a, b) {
      if (a.version == unreleasedVersion) return -1;
      if (b.version == unreleasedVersion) return 1;
      return -_compareVersions(a.version, b.version); // descending
    });

    return entries;
  }

  /// Returns entries between [lastSeenVersion] (exclusive) and
  /// [currentVersion] (inclusive).
  ///
  /// The Unreleased section is always included if the versions differ
  /// and the user is not on a first install.
  List<ChangelogEntry> filterUnseen(
    List<ChangelogEntry> allEntries,
    String lastSeenVersion,
    String currentVersion,
  ) {
    final seen = <ChangelogEntry>[];
    final currentSemver = _toSemver(currentVersion);

    for (final entry in allEntries) {
      if (entry.version == unreleasedVersion) {
        // Always show [Unreleased] when upgrading — it represents current
        // development changes not yet in a tagged release.
        seen.add(entry);
        continue;
      }

      final entrySemver = _toSemver(entry.version);
      final lastSeenSemver = _toSemver(lastSeenVersion);

      if (_compareSegments(entrySemver, lastSeenSemver) > 0 &&
          _compareSegments(entrySemver, currentSemver) <= 0) {
        seen.add(entry);
      }
    }

    return seen;
  }

  /// Compares two version strings using numeric segment comparison.
  ///
  /// Returns a negative value if [a] < [b], zero if equal, positive if
  /// [a] > [b].
  int _compareVersions(String a, String b) {
    return _compareSegments(_toSemver(a), _toSemver(b));
  }

  /// Converts a version string (e.g. `'1.0.0+1'` or `'0.1.0'`) to a list
  /// of integer segments, stripping the build-metadata suffix (`+...`).
  List<int> _toSemver(String version) {
    final cleaned = version.split('+').first;
    final parts = cleaned.split('.');
    final segments = <int>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed != null) segments.add(parsed);
    }
    // Pad to at least 3 segments for consistent comparison.
    while (segments.length < 3) {
      segments.add(0);
    }
    return segments;
  }

  int _compareSegments(List<int> a, List<int> b) {
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final va = i < a.length ? a[i] : 0;
      final vb = i < b.length ? b[i] : 0;
      final cmp = va.compareTo(vb);
      if (cmp != 0) return cmp;
    }
    return 0;
  }
}
