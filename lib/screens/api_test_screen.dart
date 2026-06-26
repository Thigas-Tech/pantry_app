import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/services/exceptions.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _fetchProduct() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching...';
    });

    try {
      final api = ref.read(apiServiceProvider);
      final product = await api.getByBarcode('3017620422003'); // Nutella
      setState(() {
        _result =
            '✅ ${product.name}\n'
            'Energy: ${product.energyKcal} kcal/100g\n'
            'Brand: ${product.brand}';
      });
    } on ProductNotFoundException catch (e) {
      setState(() => _result = 'Not found: $e');
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              if (_result.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(_result, textAlign: TextAlign.center),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchProduct,
                child: const Text('Fetch Nutella (OFF)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
