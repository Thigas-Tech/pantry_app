import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/settings_provider.dart';

/// A full-screen swipeable onboarding flow shown to first-time users.
///
/// Displays five pages in a [PageView], each with a large icon, title,
/// description, and a call-to-action button. A bottom bar provides a Back
/// button (from page 2 onward), animated progress dots, and a Next/Get
/// Started button.
class OnboardingFlow extends StatefulWidget {
  /// Creates an [OnboardingFlow] with callbacks for each page's CTA and
  /// for completing/skipping the flow.
  const OnboardingFlow({
    required this.onScanBarcode,
    required this.onSearchProduct,
    required this.onAddProduce,
    required this.onGetStarted,
    super.key,
  });

  /// Opens the barcode scanner.
  final VoidCallback onScanBarcode;

  /// Opens the product search screen.
  final VoidCallback onSearchProduct;

  /// Opens the search screen.
  final VoidCallback onAddProduce;

  /// Completes the onboarding flow.
  final VoidCallback onGetStarted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const _pageCount = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      unawaited(
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: widget.onGetStarted,
            child: Text(l10n.onboardingSkip),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _OnboardingPage(
                icon: Icons.qr_code_scanner_outlined,
                title: l10n.onboardingPage1Title,
                description: l10n.onboardingPage1Desc,
                ctaLabel: l10n.onboardingPage1Cta,
                onCta: widget.onScanBarcode,
                colorScheme: colorScheme,
              ),
              _OnboardingPage(
                icon: Icons.search_outlined,
                title: l10n.onboardingPage2Title,
                description: l10n.onboardingPage2Desc,
                ctaLabel: l10n.onboardingPage2Cta,
                onCta: widget.onSearchProduct,
                colorScheme: colorScheme,
              ),
              _OnboardingPage(
                icon: Icons.eco_outlined,
                title: l10n.onboardingPage3Title,
                description: l10n.onboardingPage3Desc,
                ctaLabel: l10n.onboardingPage3Cta,
                onCta: widget.onAddProduce,
                colorScheme: colorScheme,
              ),
              _OnboardingSettingsPage(colorScheme: colorScheme),
              _OnboardingPage(
                icon: Icons.inventory_2_outlined,
                title: l10n.onboardingPage5Title,
                description: l10n.onboardingPage5Desc,
                ctaLabel: l10n.onboardingPage5Cta,
                onCta: widget.onGetStarted,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: _currentPage > 0
                    ? TextButton(
                        onPressed: _previousPage,
                        child: Text(l10n.onboardingBack),
                      )
                    : null,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_pageCount, _buildDot),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _nextPage,
                child: Text(
                  _currentPage == _pageCount - 1
                      ? l10n.onboardingPage5Cta
                      : _currentPage == _pageCount - 2
                      ? l10n.onboardingPage4Cta
                      : 'Next',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withAlpha(77),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onCta,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onCta;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(icon, size: 96, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            onPressed: onCta,
            icon: Icon(icon),
            label: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSettingsPage extends StatelessWidget {
  const _OnboardingSettingsPage({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Consumer(
        builder: (context, ref, _) {
          final settings =
              ref.watch(settingsProvider).value ?? const Settings();

          return Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.tune_outlined,
                size: 96,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingPage4Title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingPage4Desc,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    _SettingsTile(
                      title: l10n.priceTrackingEnabled,
                      trailing: Switch.adaptive(
                        value: settings.priceTrackingEnabled,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setPriceTrackingEnabled(value: v),
                      ),
                    ),
                    _SettingsTile(
                      title: l10n.currency,
                      subtitle: settings.baseCurrency,
                      onTap: () => _showCurrencyPicker(
                        context,
                        ref,
                        settings.baseCurrency,
                      ),
                    ),
                    _SettingsTile(
                      title: l10n.dataRetention,
                      subtitle: l10n.retentionDaysValue(settings.retentionDays),
                      onTap: () => _showIntDialog(
                        context,
                        ref,
                        title: l10n.dataRetention,
                        currentValue: settings.retentionDays,
                        min: 7,
                        max: 365,
                        onSave: (v) => ref
                            .read(settingsProvider.notifier)
                            .setRetentionDays(v),
                      ),
                    ),
                    _SettingsTile(
                      title: l10n.expiringSoonDays,
                      subtitle: l10n.expiringSoonDaysValue(
                        settings.expiringSoonDays,
                      ),
                      onTap: () => _showIntDialog(
                        context,
                        ref,
                        title: l10n.expiringSoonDays,
                        currentValue: settings.expiringSoonDays,
                        min: 1,
                        max: 30,
                        onSave: (v) => ref
                            .read(settingsProvider.notifier)
                            .setExpiringSoonDays(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    const currencies = [
      'USD',
      'BRL',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'CHF',
      'ARS',
      'MXN',
      'CNY',
      'INR',
      'KRW',
      'SEK',
      'NOK',
      'DKK',
      'PLN',
      'CZK',
      'CLP',
      'COP',
      'ZAR',
      'NGN',
      'TRY',
      'ILS',
      'SGD',
      'HKD',
      'TWD',
      'THB',
      'MYR',
      'PHP',
      'IDR',
      'VND',
      'RUB',
    ];
    unawaited(
      showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.baseCurrency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 300,
                child: ListView(
                  children: currencies.map((code) {
                    final isSelected = code == current;
                    return ListTile(
                      title: Text(code),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setBaseCurrency(code);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIntDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required void Function(int) onSave,
  }) {
    final controller = TextEditingController(text: currentValue.toString());
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: title,
              helperText: '$min – $max days',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text);
                if (parsed != null && parsed >= min && parsed <= max) {
                  onSave(parsed);
                  Navigator.pop(ctx);
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
