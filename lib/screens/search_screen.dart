import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/widgets/search_panel.dart';

/// A search screen that wraps [SearchPanel] in a standalone route.
///
/// Used from onboarding flows and the FAB action sheet.
/// For inline search on the home screen, [SearchPanel] is used directly.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates a [SearchScreen] widget.
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: const SearchPanel(),
    );
  }
}
