import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/services/changelog_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a bottom sheet listing changelog entries since the last seen version.
///
/// [entries] should be the result of [ChangelogParser.parse] filtered by
/// [ChangelogParser.filterUnseen].
///
/// Returns `true` on explicit dismiss (button tap), `null` on swipe-away.
/// In both cases the caller should mark the changelog as seen.
Future<bool?> showWhatsNewSheet(
  BuildContext context,
  List<ChangelogEntry> entries,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _WhatsNewSheet(entries: entries),
  );
}

/// The content of the "What's New" bottom sheet.
///
/// Renders each [ChangelogEntry] as a version header followed by its
/// content sections grouped under `### Section` headings.
class _WhatsNewSheet extends StatelessWidget {
  /// Creates a [_WhatsNewSheet].
  const _WhatsNewSheet({required this.entries});

  /// The changelog entries to display, newest first.
  final List<ChangelogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

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
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.whatsNewDismiss,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  for (final entry in entries) ...[
                    const SizedBox(height: 12),
                    _VersionHeader(entry: entry),
                    const SizedBox(height: 8),
                    _SectionContent(content: entry.content),
                    const Divider(),
                  ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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

/// Displays a version header for a single [ChangelogEntry].
class _VersionHeader extends StatelessWidget {
  /// Creates a [_VersionHeader].
  const _VersionHeader({required this.entry});

  /// The changelog entry to display the version header for.
  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayVersion = entry.version == ChangelogParser.unreleasedVersion
        ? 'Unreleased'
        : entry.version;

    return Text(
      l10n.whatsNewVersion(displayVersion),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Renders the content of a changelog section as grouped `###` subsections.
///
/// Parses the raw [content] string, splits by `### Section` headers, and
/// renders each subsection with its header and bullet-point list.
class _SectionContent extends StatelessWidget {
  /// Creates a [_SectionContent].
  const _SectionContent({required this.content});

  /// The raw content body from a [ChangelogEntry].
  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final sections = <_ChangelogSection>[];
    final parts = content.split(RegExp(r'(?:^|\n)### '));
    var isFirst = true;

    for (final part in parts) {
      if (isFirst) {
        isFirst = false;
        // Content before the first `###` heading.
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          sections.add(_ChangelogSection(body: trimmed));
        }
        continue;
      }

      final headerEnd = part.indexOf('\n');
      final title = headerEnd == -1
          ? part.trim()
          : part.substring(0, headerEnd).trim();
      final lines = headerEnd == -1 ? '' : part.substring(headerEnd + 1).trim();

      sections.add(_ChangelogSection(title: title, body: lines));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in sections) ...[
          if (section.title != null && section.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                section.title!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (section.body.isNotEmpty) _buildBody(section.body, theme),
        ],
      ],
    );
  }

  Widget _buildBody(String body, ThemeData theme) {
    final lines = body.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Strip leading `- ` bullet marker.
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
///
/// Supported formatting:
/// - `**bold**` or `__bold__` — rendered in bold.
/// - `` `code` `` — rendered in monospace.
/// - `[link text](url)` — rendered as a tappable link via `url_launcher`.
class _MarkdownLine extends StatelessWidget {
  /// Creates a [_MarkdownLine].
  const _MarkdownLine({required this.text});

  /// The raw text of a single line, already stripped of bullet markers.
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

      // Find the earliest match.
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

      // Text before the match.
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

/// Internal model for a grouped subsection of changelog content.
class _ChangelogSection {
  /// Creates a [_ChangelogSection].
  const _ChangelogSection({required this.body, this.title});

  /// The `### Section` heading text, or `null` for ungrouped content.
  final String? title;

  /// The body content under this section heading.
  final String body;
}
