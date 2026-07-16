import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a bottom sheet with the user-facing changelog.
///
/// [rawChangelog] is the raw content of `USER_CHANGELOG.md`, which is already
/// written in user-facing language and needs no cleaning.
///
/// Returns `true` on explicit dismiss (button tap), `null` on swipe-away.
Future<bool?> showWhatsNewSheet(
  BuildContext context, {
  required String rawChangelog,
}) {
  return BottomSheetHelper.show<bool>(
    context: context,
    builder: (ctx) => _WhatsNewSheet(rawChangelog: rawChangelog),
  );
}

/// Parsed entry from the raw changelog string.
final class _ChangelogEntry {
  const _ChangelogEntry({required this.version, required this.content});

  final String version;
  final String content;
}

/// Parses a raw versioned changelog string into entries.
List<_ChangelogEntry> _parseEntries(String raw) {
  final entries = <_ChangelogEntry>[];
  final sections = raw.split(RegExp(r'(?:^|\n)## \['));
  var isFirst = true;

  for (final section in sections) {
    if (isFirst) {
      isFirst = false;
      if (!section.trimLeft().startsWith('[')) continue;
    }

    final headerEnd = section.indexOf(']');
    if (headerEnd == -1) continue;

    final version = section.substring(0, headerEnd).trim();
    if (version.isEmpty) continue;

    final bodyStart = section.indexOf('\n');
    final content = bodyStart == -1
        ? ''
        : section.substring(bodyStart + 1).trim();

    entries.add(_ChangelogEntry(version: version, content: content));
  }

  return entries;
}

/// The content of the "What's New" bottom sheet.
class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet({required this.rawChangelog});

  final String rawChangelog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxHeight = (screenHeight - bottomPadding) * 0.8;
    final entries = _parseEntries(rawChangelog);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.whatsNewTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.isEmpty ? 1 : entries.length,
              itemBuilder: (context, index) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.whatsNewDismiss,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                final entry = entries[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    _VersionHeader(version: entry.version),
                    const SizedBox(height: 8),
                    _SectionContent(content: entry.content),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + BottomSheetHelper.bottomInset(context),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.whatsNewDismiss),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a version header.
class _VersionHeader extends StatelessWidget {
  const _VersionHeader({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayVersion = version == 'Unreleased'
        ? l10n.unreleasedVersion
        : version;

    return Text(
      l10n.whatsNewVersion(displayVersion),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Renders the content of a changelog entry, grouped by `###` subsections.
class _SectionContent extends StatelessWidget {
  const _SectionContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final parts = content.split(RegExp(r'(?:^|\n)### '));
    final children = <Widget>[];
    var isFirst = true;

    for (final part in parts) {
      String? title;
      String body;

      if (isFirst) {
        isFirst = false;
        body = part.trim();
        if (body.isEmpty) continue;
      } else {
        final headerEnd = part.indexOf('\n');
        title = headerEnd == -1
            ? part.trim()
            : part.substring(0, headerEnd).trim();
        body = headerEnd == -1 ? '' : part.substring(headerEnd + 1).trim();
        if (body.isEmpty) continue;
      }

      if (title != null && title.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      children.add(_buildBody(body, theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBody(String body, ThemeData theme) {
    final lines = body.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final displayText = trimmed.startsWith('- ')
          ? trimmed.substring(2).trim()
          : trimmed;

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _MarkdownLine(text: displayText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Renders a single line of changelog content with basic markdown support.
class _MarkdownLine extends StatelessWidget {
  const _MarkdownLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parseLine(context),
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  InlineSpan _parseLine(BuildContext context) {
    final spans = <InlineSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      final boldMatch = RegExp(r'\*\*(.+?)\*\*').firstMatch(remaining);
      final boldAltMatch = RegExp('__(.+?)__').firstMatch(remaining);
      final codeMatch = RegExp('`([^`]+)`').firstMatch(remaining);
      final linkMatch = RegExp(
        r'\[([^\]]+)\]\(([^)]+)\)',
      ).firstMatch(remaining);

      var earliest = boldMatch;
      if (boldAltMatch != null &&
          (earliest == null || boldAltMatch.start < earliest.start)) {
        earliest = boldAltMatch;
      }
      if (codeMatch != null &&
          (earliest == null || codeMatch.start < earliest.start)) {
        earliest = codeMatch;
      }
      if (linkMatch != null &&
          (earliest == null || linkMatch.start < earliest.start)) {
        earliest = linkMatch;
      }

      if (earliest == null) {
        spans.add(TextSpan(text: remaining));
        remaining = '';
        break;
      }

      if (earliest.start > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliest.start)));
      }

      final matchedText = earliest.group(1)!;
      final style = TextStyle(
        fontWeight: (earliest == boldMatch || earliest == boldAltMatch)
            ? FontWeight.bold
            : null,
        fontFamily: earliest == codeMatch ? 'monospace' : null,
        color: earliest == linkMatch
            ? Theme.of(context).colorScheme.primary
            : null,
      );

      if (earliest == linkMatch) {
        final url = earliest.group(2)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                unawaited(_tryLaunchUrl(context, url));
              },
              child: Text(
                matchedText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: matchedText, style: style));
      }

      remaining = remaining.substring(earliest.end);
    }

    return TextSpan(children: spans);
  }
}

Future<void> _tryLaunchUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    // Silently ignore failed link launches.
  }
}
