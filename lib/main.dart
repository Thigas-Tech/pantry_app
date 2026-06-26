import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/services/exceptions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PantryApp()));
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pantry',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final barcode = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScannerScreen()));

    if (barcode == null || !context.mounted) return;

    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProduct(barcode);

      if (context.mounted) {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
        );
      }
    } on ProductNotFoundException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product not found')));
      }
    } on FetchFailedException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry')),
      body: const Center(child: Text('Hello Pantry')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanBarcode(context, ref),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
