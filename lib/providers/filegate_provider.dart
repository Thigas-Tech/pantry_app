import 'package:filegate/filegate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [Filegate] instance. Override in tests to mock file picking.
final filegateProvider = Provider<Filegate>((ref) => const Filegate());
