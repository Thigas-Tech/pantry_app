# Dart VM Service — Health Check & Profiling

The Dart VM Service is a WebSocket-based introspection protocol exposed by every
running Dart or Flutter application in debug mode. It provides real-time access
to isolate state, memory usage, CPU samples, and registered service extensions.

## Quick start

1. Start the app in debug mode:

   ```bash
   flutter run --debug --device-id emulator-5554
   ```

2. Extract the VM Service URI from the output. Look for the line:

   ```
   A Dart VM Service on sdk gphone64 x86 64 is available at: http://127.0.0.1:XXXXX/YYYYYYYYYYYY=/
   ```

3. The WebSocket endpoint is the same URI with `ws://` instead of `http://`:

   ```
   ws://127.0.0.1:XXXXX/YYYYYYYYYYYY=/
   ```

4. Connect and query using `package:vm_service`:

   ```dart
   import 'package:vm_service/vm_service.dart';
   import 'package:vm_service/vm_service_io.dart';

   Future<void> main(List<String> args) async {
     final uri = args.isNotEmpty
         ? args.first
         : 'ws://127.0.0.1:8180/SECRET=/';
     final service = await vmServiceConnectUri(uri);

     final vm = await service.getVM();
     print('VM: ${vm.name} (version ${vm.version})');

     for (final isolate in vm.isolates ?? []) {
       print('Isolate: ${isolate.name} (${isolate.id})');

       final mem = await service.getMemoryUsage(isolate.id!);
       print('  Heap: ${mem.heapUsage} / ${mem.heapCapacity}');
       print('  External: ${mem.externalUsage}');
       print('  RSS: ${(mem.rss ?? 0) ~/ (1024 * 1024)} MB');

       print('  Extensions: ${isolate.extensionRPCs?.length ?? 0}');
     }

     await service.dispose();
   }
   ```

## Key API calls

| Method | Returns | Purpose |
|--------|---------|---------|
| `getVM()` | `VM` | VM name, version, list of isolates, service extensions |
| `getIsolate(id)` | `Isolate` | Detailed isolate info (name, heap, library count) |
| `getMemoryUsage(id)` | `MemoryUsage` | Heap used/capacity, external memory, RSS |
| `getCpuSamples(id)` | `CpuSamples` | Recent CPU profiling samples (call stack, function names) |
| `getFlagList()` | `FlagList` | All VM flags and their current values |
| `setFlag(name, value)` | `Response` or `Success` | Toggle VM flags (e.g. pause isolates on start) |
| `getVersion()` | `Version` | VM service protocol version (for compatibility checks) |

## Service extensions

Service extensions are custom RPCs registered by libraries or the framework.
Common Flutter extensions include:

| Extension | Purpose |
|-----------|---------|
| `ext.flutter.reassemble` | Hot reload |
| `ext.flutter.hotRestart` | Hot restart |
| `ext.flutter.inspector.fetch` | Fetch widget tree from Flutter Inspector |
| `ext.flutter.inspector.disposeAllGroups` | Dispose all inspector object groups |
| `ext.flutter.inspector.isWidgetCreationTracked` | Widget creation tracking status |
| `ext.dart.io.getSocketProfile` | Socket profiling |
| `ext.dart.io.getHttpProfile` | HTTP request profiling |

List them from an isolate:

```dart
final isolate = await service.getIsolate(isolateId);
for (final ext in isolate.extensionRPCs ?? []) {
  print(ext);
}
```

## VM Service vs DTD

| Aspect | VM Service | DTD (Dart Tooling Daemon) |
|--------|-----------|---------------------------|
| Protocol | WebSocket (VM service protocol) | HTTP/WebSocket (Dart DevTools bridge) |
| Scope | Raw VM introspection | Higher-level Flutter tooling |
| Accessible via | Direct WebSocket connection | Flutter DevTools, `dart devtools`, IDEs |
| Widget tree | Not available | Available via `ext.flutter.inspector.*` |
| Depends on | Dart VM | VM Service + Flutter framework |

## Health check tool

This project includes `tools/vm_health_check.dart` — a CLI utility that connects
to a running debug session and produces a health report. Run it with:

```bash
dart run tools/vm_health_check.dart ws://127.0.0.1:XXXXX/SECRET=/
```

Or use `curl` directly against the VM Service URI printed by `flutter run`:

```bash
curl -s "http://127.0.0.1:8181/api/v1/health" 2>/dev/null || \
  echo "Adjust host:port to match the VM Service URI from flutter run output"
```

## Common pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| **Stale endpoint** | `WebSocketChannelException` / connection refused | The secret in the URI changes every `flutter run`. Extract fresh URI each time. |
| **VM not ready** | `getVM()` returns 0 isolates | Poll `getVM()` every 500ms for up to 10 attempts after app start. |
| **Memory API returns null** | `getMemoryUsage()` returns null for VM isolate | Skip VM isolates; only query app isolates. |
| **CPU samples empty** | `getCpuSamples()` returns no data | The profiler may need a brief warm-up. Collect samples over a few seconds. |
| **Auth token mismatch** | WebSocket connection refused | The secret path in the URI (`/SECRET=`) is a per-session capability token. Must match exactly. |
| **Debug vs profile memory** | Heap usage is 3-5x higher in debug mode | This is expected — JIT and debugging overhead. Use profile mode (`--profile`) for memory baselines. |
| **Protocol version skew** | API call returns unexpected fields or errors | Check `getVersion()` output. The `vm_service` package version must match the Dart SDK version on the device. |
