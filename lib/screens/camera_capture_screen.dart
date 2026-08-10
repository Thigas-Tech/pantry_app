import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/camera_capture_result.dart';
import 'package:pantry_app/services/camera_image_processor.dart';
import 'package:pantry_app/utils/logger.dart';

/// Creates a [CameraController] for a [CameraDescription].
typedef CameraControllerFactory =
    CameraController Function(
      CameraDescription description,
    );

/// An in-app camera screen that captures a product photo with a known lens.
///
/// The screen shows a live preview, a shutter button, and a cancel button. On
/// a successful capture the photo is normalized via [CameraImageProcessor]
/// and the screen pops with [CameraCaptured]. Closing the screen pops with
/// [CameraCaptureCancelled], and a failure to open the camera pops with
/// [CameraCaptureUnavailable].
///
/// [controllerFactory] and [processor] are injectable for tests. The
/// controller is created with [ResolutionPreset.max] and audio disabled
/// because only still photos are captured.
class CameraCaptureScreen extends StatefulWidget {
  /// Creates a [CameraCaptureScreen] for [camera].
  const CameraCaptureScreen({
    required this.camera,
    super.key,
    this.controllerFactory,
    this.processor,
  });

  /// The camera device to open, selected before pushing this screen.
  final CameraDescription camera;

  /// Creates the [CameraController] used to capture; defaults to a real
  /// controller. Injectable for tests.
  final CameraControllerFactory? controllerFactory;

  /// Normalizes the captured photo; defaults to [CameraImageProcessor].
  /// Injectable for tests.
  final CameraImageProcessor? processor;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  var _initializing = true;
  var _unavailable = false;
  var _capturing = false;
  var _wasPaused = false;

  CameraImageProcessor get _processor =>
      widget.processor ?? CameraImageProcessor();

  CameraController _createController() {
    final factory = widget.controllerFactory;
    return factory != null
        ? factory(widget.camera)
        : CameraController(
            widget.camera,
            ResolutionPreset.max,
            enableAudio: false,
          );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _createController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
    } on CameraException catch (e) {
      logWarning(
        'Camera initialize failed: code=${e.code} '
        'description=${e.description}',
      );
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _unavailable = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPaused = true;
        if (_controller.value.isInitialized && !_unavailable) {
          unawaited(_controller.dispose());
        }
      case AppLifecycleState.resumed:
        if (_wasPaused && !_unavailable) {
          _wasPaused = false;
          _controller = _createController();
          unawaited(_initialize());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _capture() async {
    if (_capturing || _unavailable || !_controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final picked = await _controller.takePicture();
      final file = await _processor.resizeToStandard(File(picked.path));
      if (!mounted) return;
      Navigator.of(context).pop(CameraCaptured(file));
    } on CameraException catch (e) {
      logWarning('Take picture failed: ${e.code} ${e.description}');
      if (!mounted) return;
      setState(() => _capturing = false);
    }
  }

  void _cancel() {
    Navigator.of(context).pop(const CameraCaptureCancelled());
  }

  void _closeUnavailable() {
    Navigator.of(context).pop(const CameraCaptureUnavailable());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_unavailable)
              _UnavailableView(message: l10n.cameraNotAvailable)
            else if (!_initializing && _controller.value.isInitialized)
              _buildPreview()
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_unavailable)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Center(
                  child: FilledButton(
                    onPressed: _closeUnavailable,
                    child: Text(l10n.close),
                  ),
                ),
              )
            else if (!_initializing && _controller.value.isInitialized) ...[
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: _cancel,
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  tooltip: l10n.cancel,
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _ShutterButton(
                    onPressed: _capture,
                    enabled: !_capturing,
                    label: l10n.takePhoto,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Transform.scale(
      scale: _calculateScale(),
      child: Center(child: CameraPreview(_controller)),
    );
  }

  double _calculateScale() {
    final size = MediaQuery.sizeOf(context);
    final previewSize = _controller.value.previewSize;
    if (previewSize == null) return 1;
    final scale = size.aspectRatio / (previewSize.height / previewSize.width);
    if (scale < 1) return scale;
    return 1;
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.onPressed,
    required this.enabled,
    required this.label,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: enabled ? Colors.white : Colors.white38,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: const SizedBox(
            width: 72,
            height: 72,
            child: Icon(Icons.photo_camera, color: Colors.black87, size: 36),
          ),
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
