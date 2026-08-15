// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_panel_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that owns all search state and execution for the search panel.
///
/// This is an auto-dispose provider family keyed by the search debounce
/// duration, so state lives exactly as long as the hosting search panel
/// widget and each panel instance is isolated.
///
/// The notifier handles query changes (debounced and on-submit), source
/// switching, the stale-response race guard, pantry enrichment, and all three
/// search implementations (OFF, USDA, and inventory). UI concerns such as
/// navigation, snackbars, and the long-press menu live in the widget layer.

@ProviderFor(SearchPanelController)
final searchPanelControllerProvider = SearchPanelControllerFamily._();

/// Notifier that owns all search state and execution for the search panel.
///
/// This is an auto-dispose provider family keyed by the search debounce
/// duration, so state lives exactly as long as the hosting search panel
/// widget and each panel instance is isolated.
///
/// The notifier handles query changes (debounced and on-submit), source
/// switching, the stale-response race guard, pantry enrichment, and all three
/// search implementations (OFF, USDA, and inventory). UI concerns such as
/// navigation, snackbars, and the long-press menu live in the widget layer.
final class SearchPanelControllerProvider
    extends $NotifierProvider<SearchPanelController, SearchPanelState> {
  /// Notifier that owns all search state and execution for the search panel.
  ///
  /// This is an auto-dispose provider family keyed by the search debounce
  /// duration, so state lives exactly as long as the hosting search panel
  /// widget and each panel instance is isolated.
  ///
  /// The notifier handles query changes (debounced and on-submit), source
  /// switching, the stale-response race guard, pantry enrichment, and all three
  /// search implementations (OFF, USDA, and inventory). UI concerns such as
  /// navigation, snackbars, and the long-press menu live in the widget layer.
  SearchPanelControllerProvider._({
    required SearchPanelControllerFamily super.from,
    required Duration super.argument,
  }) : super(
         retry: null,
         name: r'searchPanelControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchPanelControllerHash();

  @override
  String toString() {
    return r'searchPanelControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchPanelController create() => SearchPanelController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchPanelState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchPanelState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPanelControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchPanelControllerHash() =>
    r'70931c6cdc2371b5dd0c894c84ca9118ee79f6c6';

/// Notifier that owns all search state and execution for the search panel.
///
/// This is an auto-dispose provider family keyed by the search debounce
/// duration, so state lives exactly as long as the hosting search panel
/// widget and each panel instance is isolated.
///
/// The notifier handles query changes (debounced and on-submit), source
/// switching, the stale-response race guard, pantry enrichment, and all three
/// search implementations (OFF, USDA, and inventory). UI concerns such as
/// navigation, snackbars, and the long-press menu live in the widget layer.

final class SearchPanelControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchPanelController,
          SearchPanelState,
          SearchPanelState,
          SearchPanelState,
          Duration
        > {
  SearchPanelControllerFamily._()
    : super(
        retry: null,
        name: r'searchPanelControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier that owns all search state and execution for the search panel.
  ///
  /// This is an auto-dispose provider family keyed by the search debounce
  /// duration, so state lives exactly as long as the hosting search panel
  /// widget and each panel instance is isolated.
  ///
  /// The notifier handles query changes (debounced and on-submit), source
  /// switching, the stale-response race guard, pantry enrichment, and all three
  /// search implementations (OFF, USDA, and inventory). UI concerns such as
  /// navigation, snackbars, and the long-press menu live in the widget layer.

  SearchPanelControllerProvider call(Duration searchDebounceDuration) =>
      SearchPanelControllerProvider._(
        argument: searchDebounceDuration,
        from: this,
      );

  @override
  String toString() => r'searchPanelControllerProvider';
}

/// Notifier that owns all search state and execution for the search panel.
///
/// This is an auto-dispose provider family keyed by the search debounce
/// duration, so state lives exactly as long as the hosting search panel
/// widget and each panel instance is isolated.
///
/// The notifier handles query changes (debounced and on-submit), source
/// switching, the stale-response race guard, pantry enrichment, and all three
/// search implementations (OFF, USDA, and inventory). UI concerns such as
/// navigation, snackbars, and the long-press menu live in the widget layer.

abstract class _$SearchPanelController extends $Notifier<SearchPanelState> {
  late final _$args = ref.$arg as Duration;
  Duration get searchDebounceDuration => _$args;

  SearchPanelState build(Duration searchDebounceDuration);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchPanelState, SearchPanelState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchPanelState, SearchPanelState>,
              SearchPanelState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
