/// Dart VM Service health check CLI tool.
///
/// Connects to a running Flutter/Dart app in debug mode and produces
/// a diagnostic report covering isolates, memory usage, CPU samples,
/// and registered service extensions.
///
/// Usage:
///   dart run tools/vm_health_check.dart ws://127.0.0.1:XXXXX/SECRET=/
///
/// The VM Service URI is printed by `flutter run` on startup:
///   A Dart VM Service on ... is available at: http://127.0.0.1:XXXXX/SECRET=/
/// Replace `http://` with `ws://` for this tool.

import 'dart:async';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tools/vm_health_check.dart <ws-uri>');
    stderr.writeln(
      'Example: dart run tools/vm_health_check.dart '
      'ws://127.0.0.1:12345/SECRET=/',
    );
    exit(1);
  }

  final uri = args.first;
  if (!uri.startsWith('ws://') && !uri.startsWith('wss://')) {
    stderr.writeln('Error: URI must start with ws:// or wss://');
    stderr.writeln('Got: $uri');
    exit(1);
  }

  stdout.writeln('Connecting to $uri ...');
  VmService? service;
  try {
    service = await vmServiceConnectUri(uri).timeout(
      const Duration(seconds: 10),
    );
  } on TimeoutException {
    stderr.writeln(
      'Error: Connection timed out. Is the app running in debug mode?',
    );
    exit(1);
  } on WebSocketException catch (e) {
    stderr.writeln('Error: Failed to connect: $e');
    stderr.writeln('The VM Service URI changes every flutter run session.');
    exit(1);
  }

  stdout.writeln('Connected. Fetching VM info...\n');

  try {
    await _runDiagnostics(service);
  } finally {
    await service.dispose();
  }
}

Future<void> _runDiagnostics(VmService service) async {
  final vm = await service.getVM();
  _printHeader('VM Overview');
  stdout.writeln('  Name:      ${vm.name}');
  stdout.writeln('  Version:   ${vm.version}');
  stdout.writeln('  PID:       ${vm.pid}');
  stdout.writeln('  Isolates:  ${vm.isolates?.length ?? 0}');
  stdout.writeln('  Uptime:    ${_formatUptime(vm.startTime)}');

  final isolateRefs = vm.isolates ?? [];
  if (isolateRefs.isEmpty) {
    stdout.writeln('\n  No isolates found — app may still be starting.');
    return;
  }

  int warnings = 0;

  for (final ref in isolateRefs) {
    final isolateId = ref.id;
    if (isolateId == null || isolateId.isEmpty) continue;

    final isolate = await service.getIsolate(isolateId);
    _printHeader('Isolate: ${isolate.name ?? '(unnamed)'}');
    stdout.writeln('  ID:            ${isolate.id}');

    warnings += await _printMemoryUsage(service, isolateId);
    warnings += await _printCpuSamples(service, isolateId);

    final extensions = isolate.extensionRPCs ?? [];
    stdout.writeln('  Extensions:    ${extensions.length} registered');
    _printFlutterExtensions(extensions);
  }

  _printHeader('Health Assessment');
  if (warnings == 0) {
    stdout.writeln('  Status:  PASS — no warnings detected');
  } else {
    stdout.writeln('  Status:  WARN — $warnings warning(s) found');
  }
}

Future<int> _printMemoryUsage(VmService service, String isolateId) async {
  final mem = await service.getMemoryUsage(isolateId);
  final heapUsed = (mem.heapUsage ?? 0) ~/ (1024 * 1024);
  final heapCapacity = (mem.heapCapacity ?? 0) ~/ (1024 * 1024);
  final external = (mem.externalUsage ?? 0) ~/ (1024 * 1024);

  stdout.writeln('  Memory:');
  stdout.writeln('    Heap:      $heapUsed MB / $heapCapacity MB');
  stdout.writeln('    External:  $external MB');

  int warnings = 0;
  if (heapCapacity > 0 && heapUsed > heapCapacity * 0.85) {
    stdout.writeln('    WARNING: Heap usage > 85% — may trigger GC pressure.');
    warnings++;
  }
  return warnings;
}

Future<int> _printCpuSamples(VmService service, String isolateId) async {
  try {
    final now = DateTime.now().microsecondsSinceEpoch;
    final samples = await service.getCpuSamples(
      isolateId,
      now - 3000000,
      3000000,
    );
    final funcList = samples.functions ?? [];

    final counts = <String, int>{};
    for (final sample in samples.samples ?? <CpuSample>[]) {
      final stack = sample.stack;
      if (stack != null && stack.isNotEmpty) {
        final topIndex = stack.first;
        if (topIndex < funcList.length) {
          final func = funcList[topIndex];
          final ref = func.function;
          final name = ref is FuncRef
              ? (ref.name ?? func.resolvedUrl ?? '<anon>')
              : (func.resolvedUrl ?? '<anon>');
          counts[name] = (counts[name] ?? 0) + 1;
        }
      }
    }

    stdout.writeln('  CPU (top 5 functions):');
    final sorted = counts.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted.take(5)) {
      stdout.writeln('    ${entry.key}: ${entry.value} samples');
    }
    if (sorted.isEmpty) {
      stdout.writeln('    No CPU samples collected yet.');
    }
  } on Exception {
    stdout.writeln('  CPU: not available');
  }
  return 0;
}

void _printFlutterExtensions(List<String> extensions) {
  final flutterExts = extensions.where((e) => e.startsWith('ext.flutter.'));
  if (flutterExts.isNotEmpty) {
    stdout.writeln('  Flutter extensions:');
    for (final ext in flutterExts) {
      stdout.writeln('    $ext');
    }
  }
}

void _printHeader(String text) {
  stdout.writeln('\n${'─' * 60}');
  stdout.writeln('  $text');
  stdout.writeln('${'─' * 60}');
}

String _formatUptime(int? startTime) {
  if (startTime == null) return 'unknown';
  final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
  final seconds = elapsed ~/ 1000;
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  if (hours > 0) return '${hours}h ${minutes % 60}m';
  if (minutes > 0) return '${minutes}m ${seconds % 60}s';
  return '${seconds}s';
}
