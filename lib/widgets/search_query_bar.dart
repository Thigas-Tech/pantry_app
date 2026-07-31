import 'package:flutter/material.dart';
import 'package:pantry_app/providers/search_panel_controller.dart';

/// A search bar that forwards keystrokes and submissions to the parent.
///
/// Owns its own [TextEditingController] so it can show or hide the clear
/// button as the text changes. Debouncing and the actual search execution
/// live in the [SearchPanelController], so this widget is purely presentational
/// and delegates every interaction through [onChanged], [onSubmitted], and
/// [onClear].
class SearchQueryBar extends StatefulWidget {
  /// Creates a [SearchQueryBar].
  ///
  /// [searchHint] is the placeholder shown when the bar is empty.
  /// When [showBackButton] is true and [onBack] is non-null, a back arrow
  /// replaces the search icon in the leading position.
  const SearchQueryBar({
    required this.searchHint,
    super.key,
    this.autoFocus = false,
    this.showBackButton = false,
    this.onBack,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  /// The placeholder text shown when the bar is empty.
  final String searchHint;

  /// Whether to focus the search bar on first build.
  final bool autoFocus;

  /// When true, replaces the search icon leading with a back arrow.
  final bool showBackButton;

  /// Called when the back arrow is tapped (only when [showBackButton] is
  /// true).
  final VoidCallback? onBack;

  /// Called with the new text on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called with the text when the search action is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Called when the clear button is tapped, after the text has been cleared.
  final VoidCallback? onClear;

  @override
  State<SearchQueryBar> createState() => _SearchQueryBarState();
}

class _SearchQueryBarState extends State<SearchQueryBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.searchHint,
      leading: widget.showBackButton && widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            )
          : const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search),
            ),
      trailing: [
        if (_hasText)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clear,
          ),
      ],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      autoFocus: widget.autoFocus,
    );
  }
}
