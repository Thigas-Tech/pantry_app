import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/widgets/search_panel.dart';

/// A full-screen product picker that wraps [SearchPanel] in select mode.
///
/// Used by the recipe form to search for and select an ingredient product.
/// Pops the current route with the selected [Product] when a result is
/// tapped, or null if the user navigates back.
class ProductPickerScreen extends ConsumerStatefulWidget {
  /// Creates a [ProductPickerScreen].
  const ProductPickerScreen({super.key});

  @override
  ConsumerState<ProductPickerScreen> createState() =>
      _ProductPickerScreenState();
}

class _ProductPickerScreenState extends ConsumerState<ProductPickerScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchProduct)),
      body: const SearchPanel(
        selectMode: true,
        autoFocus: true,
      ),
    );
  }
}
