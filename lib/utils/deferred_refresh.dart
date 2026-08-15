import 'package:flutter/scheduler.dart';

/// Runs [action] after the current frame completes.
///
/// Used to defer provider invalidations out of the build phase: invalidating
/// a provider whose build uses ref.watch immediately before (or while) a
/// route pop resumes a paused subscriber can flush that provider during the
/// pop's TickerMode rebuild, which calls setState during build on the app's
/// UncontrolledProviderScope and throws. Deferring to the end of the frame
/// lets the refresh flush in a normal frame instead. Callers guard [action]
/// with their own mounted checks (State.mounted, context.mounted, or
/// Ref.mounted).
void afterFrame(VoidCallback action) {
  SchedulerBinding.instance.addPostFrameCallback((_) => action());
}
