import 'package:flutter/material.dart';

/// Global navigator key for pushing routes from outside the widget tree.
///
/// Passed to [MaterialApp.navigatorKey] so services without a [BuildContext]
/// (for example the in-app camera capture) can push full-screen routes. Kept
/// in its own file so services can reference it without importing the app
/// entrypoint.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
