import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

enum _Stage { initial, enteringBarcode, barcodeNotFound }

/// A progressive disclosure widget shown when a packaged product search
/// returns no results.
///
/// Guides the user through three stages:
///   * **initial** — encourages scanning or typing the barcode.
///   * **enteringBarcode** — an inline barcode text field with validation.
///   * **barcodeNotFound** — offers to contribute to OFF (stub) or save
///     locally.
///
/// Use a GlobalKey of type NotFoundFlowState and call showBarcodeNotFound on
/// the current state to transition from the entering-barcode stage to the
/// barcode-not-found stage when the barcode lookup fails.
class NotFoundFlow extends StatefulWidget {
  /// Creates a [NotFoundFlow].
  const NotFoundFlow({
    super.key,
    this.onBarcodeSubmitted,
    this.onScanBarcode,
    this.onContributeToOff,
    this.onSaveLocally,
  });

  /// Called when the user submits a valid barcode.
  final void Function(String barcode)? onBarcodeSubmitted;

  /// Called when the user taps the Scan Barcode button.
  final VoidCallback? onScanBarcode;

  /// Called with the barcode when the user taps Contribute to Open Food
  /// Facts.
  final void Function(String barcode)? onContributeToOff;

  /// Called with the barcode when the user taps Save Locally.
  final void Function(String barcode)? onSaveLocally;

  @override
  NotFoundFlowState createState() => NotFoundFlowState();
}

/// The state for [NotFoundFlow], exposing [showBarcodeNotFound] to transition
/// to the barcode-not-found stage.
class NotFoundFlowState extends State<NotFoundFlow> {
  _Stage _stage = _Stage.initial;
  String _barcode = '';
  final _barcodeController = TextEditingController();

  void _goToBarcodeEntry() {
    setState(() => _stage = _Stage.enteringBarcode);
  }

  void _goToInitial() {
    setState(() {
      _stage = _Stage.initial;
      _barcode = '';
      _barcodeController.clear();
    });
  }

  /// Transitions to the barcode-not-found stage, showing the given [barcode].
  void showBarcodeNotFound(String barcode) {
    setState(() {
      _stage = _Stage.barcodeNotFound;
      _barcode = barcode;
    });
  }

  void _submitBarcode() {
    final text = _barcodeController.text.trim();
    if (text.length < 8 || !RegExp(r'^\d+$').hasMatch(text)) {
      final l10n = AppLocalizations.of(context)!;
      SnackbarHelper.showWarning(context, l10n.invalidBarcode);
      return;
    }
    widget.onBarcodeSubmitted?.call(text);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: switch (_stage) {
          _Stage.initial => _buildInitial(theme, l10n),
          _Stage.enteringBarcode => _buildBarcodeEntry(theme, l10n),
          _Stage.barcodeNotFound => _buildBarcodeNotFound(theme, l10n),
        },
      ),
    );
  }

  Widget _buildInitial(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          l10n.productNotFoundSearch,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.productNotFoundBarcodeHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: widget.onScanBarcode,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n.scanBarcode),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _goToBarcodeEntry,
          icon: const Icon(Icons.keyboard),
          label: Text(l10n.enterBarcode),
        ),
      ],
    );
  }

  Widget _buildBarcodeEntry(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToInitial,
          alignment: Alignment.centerLeft,
          tooltip: l10n.backToSearch,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterBarcodePrompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _barcodeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: l10n.barcodeLabel,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitBarcode(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _submitBarcode,
          icon: const Icon(Icons.check),
          label: Text(l10n.submit),
        ),
      ],
    );
  }

  Widget _buildBarcodeNotFound(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          l10n.productNotInDatabase,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.productNotInDatabaseHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _barcode,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => widget.onContributeToOff?.call(_barcode),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(l10n.contributeToOpenFoodFacts),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.onSaveLocally?.call(_barcode),
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.saveLocallyAction),
        ),
      ],
    );
  }
}
