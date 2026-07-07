import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/config.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// A form that lets users submit feedback, bug reports, or feature requests
/// directly to the app's GitHub repository.
class FeedbackScreen extends ConsumerStatefulWidget {
  /// Creates a [FeedbackScreen].
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

enum _IssueType { bug, feature, feedback }

extension _IssueTypeLabel on _IssueType {
  String label(AppLocalizations l10n) => switch (this) {
    _IssueType.bug => l10n.bugReport,
    _IssueType.feature => l10n.featureRequest,
    _IssueType.feedback => l10n.generalFeedback,
  };

  String gitHubLabel() => switch (this) {
    _IssueType.bug => 'bug',
    _IssueType.feature => 'enhancement',
    _IssueType.feedback => '',
  };
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _IssueType _issueType = _IssueType.bug;
  bool _includeDeviceInfo = false;
  bool _isSubmitting = false;
  final List<String> _screenshotPaths = [];
  String? _submittedIssueUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cleanupAllScreenshots();
    super.dispose();
  }

  void _cleanupAllScreenshots() {
    for (final path in _screenshotPaths) {
      try {
        unawaited(File(path).delete());
      } on Exception {
        // best-effort cleanup
      }
    }
    _screenshotPaths.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = ref.watch(connectivityProvider).value ?? false;
    final enabled = AppConfig.feedbackEnabled;

    if (!enabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sendFeedback)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.comingSoonDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sendFeedback)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIssueTypeDropdown(l10n),
              const SizedBox(height: 16),
              _buildTitleField(l10n),
              const SizedBox(height: 16),
              _buildDescriptionField(l10n),
              const SizedBox(height: 16),
              _buildScreenshotSection(l10n),
              const SizedBox(height: 16),
              _buildDeviceInfoToggle(l10n),
              const SizedBox(height: 24),
              _buildSubmitButton(l10n),
              if (!isOnline) ...[
                const SizedBox(height: 12),
                _buildOfflineInfo(l10n),
              ],
              if (_submittedIssueUrl != null) ...[
                const SizedBox(height: 16),
                _buildSuccessCard(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypeDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<_IssueType>(
      value: _issueType,
      decoration: InputDecoration(labelText: l10n.issueType),
      items: _IssueType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.label(l10n)));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _issueType = value);
      },
    );
  }

  Widget _buildTitleField(AppLocalizations l10n) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(labelText: l10n.issueTitle),
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().length < 5) {
          return l10n.issueTitleRequired;
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(AppLocalizations l10n) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: l10n.issueDescription,
        alignLabelWithHint: true,
      ),
      maxLines: 6,
      maxLength: 5000,
      validator: (value) {
        if (value == null || value.trim().length < 10) {
          return l10n.issueDescriptionRequired;
        }
        return null;
      },
    );
  }

  Widget _buildScreenshotSection(AppLocalizations l10n) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.attachScreenshot, style: _labelStyle()),
        const SizedBox(height: 8),
        if (_screenshotPaths.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_screenshotPaths.length, (i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.file(
                      File(_screenshotPaths[i]),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeScreenshot(i),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: Text(l10n.takePhoto),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: Text(l10n.chooseFromGallery),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceInfoToggle(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.includeDeviceInfo),
      value: _includeDeviceInfo,
      onChanged: (value) => setState(() => _includeDeviceInfo = value),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    final isOnline = ref.watch(connectivityProvider).value ?? false;

    return FilledButton.icon(
      onPressed: _isSubmitting ? null : () => _submit(l10n, isOnline),
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: Text(_isSubmitting ? l10n.sending : l10n.issueCreate),
    );
  }

  Widget _buildOfflineInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.issueQueuedOffline)),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.issueSubmitted,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openIssueUrl,
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: Text(l10n.viewOnGitHub),
          ),
        ],
      ),
    );
  }

  TextStyle? _labelStyle() {
    return Theme.of(context).inputDecorationTheme.labelStyle;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (!mounted) return;
      if (picked != null) {
        setState(() => _screenshotPaths.add(picked.path));
      }
    } on Exception catch (e) {
      logWarning('Image pick failed: $e');
      if (mounted) {
        SnackbarHelper.showWarning(context, 'Could not attach image');
      }
    }
  }

  void _removeScreenshot(int index) {
    final path = _screenshotPaths.removeAt(index);
    try {
      unawaited(File(path).delete());
    } on Exception {
      // best-effort cleanup
    }
    setState(() {});
  }

  Future<void> _submit(AppLocalizations l10n, bool isOnline) async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final service = ref.read(githubIssueServiceProvider);

    if (service.isDuplicate(title, description)) {
      if (mounted) {
        SnackbarHelper.showWarning(context, l10n.issueDuplicate);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final label = _issueType.gitHubLabel();
      final effectiveLabel = label.isEmpty ? null : label;
      final body = _buildBody(description);

      final List<List<int>> screenshotBytesList = [];
      for (final path in _screenshotPaths) {
        final file = File(path);
        if (await file.exists()) {
          screenshotBytesList.add(await file.readAsBytes());
        }
      }

      if (isOnline) {
        final url = await service.submitIssue(
          title: title,
          body: body,
          label: effectiveLabel,
          screenshotBytesList: screenshotBytesList,
        );
        if (mounted) {
          setState(() => _submittedIssueUrl = url);
          SnackbarHelper.showInfo(context, l10n.issueSubmitted);
        }
      } else {
        await service.queueOffline(
          title: title,
          body: body,
          label: effectiveLabel,
          screenshotBytesList: screenshotBytesList,
        );
        if (mounted) {
          SnackbarHelper.showWarning(context, l10n.issueQueuedOffline);
        }
      }
    } on Exception catch (e) {
      logError('Feedback submission failed: $e');
      if (mounted) {
        SnackbarHelper.showError(context, l10n.issueSubmissionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _buildBody(String description) {
    final buffer = StringBuffer(description);

    if (_includeDeviceInfo) {
      buffer
        ..writeln()
        ..writeln()
        ..writeln('```')
        ..writeln('App version: 1.0')
        ..writeln(
          'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        )
        ..writeln('```');
    }

    return buffer.toString();
  }

  Future<void> _openIssueUrl() async {
    if (_submittedIssueUrl == null) return;
    final url = Uri.parse(_submittedIssueUrl!);
    if (await launcher.canLaunchUrl(url) && mounted) {
      await launcher.launchUrl(
        url,
        mode: launcher.LaunchMode.externalApplication,
      );
    } else if (mounted) {
      SnackbarHelper.showError(context, 'Could not open link');
    }
  }
}
