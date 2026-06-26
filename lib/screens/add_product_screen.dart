import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({required this.barcode, super.key});
  final String barcode;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  String? _brand;
  String? _category;
  String? _ingredients;
  double? _energy, _protein, _carbs, _fat, _fiber, _salt;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to Open Food Facts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Barcode: ${widget.barcode}'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Product name *'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Brand'),
                onSaved: (v) => _brand = v?.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Category'),
                onSaved: (v) => _category = v?.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ingredients'),
                maxLines: 3,
                onSaved: (v) => _ingredients = v?.trim(),
              ),
              const SizedBox(height: 16),
              Text(
                'Nutrition (per 100g)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _nutritionField(
                'Energy (kcal)',
                (v) => _energy = double.tryParse(v ?? ''),
              ),
              _nutritionField(
                'Protein (g)',
                (v) => _protein = double.tryParse(v ?? ''),
              ),
              _nutritionField(
                'Carbs (g)',
                (v) => _carbs = double.tryParse(v ?? ''),
              ),
              _nutritionField(
                'Fat (g)',
                (v) => _fat = double.tryParse(v ?? ''),
              ),
              _nutritionField(
                'Fiber (g)',
                (v) => _fiber = double.tryParse(v ?? ''),
              ),
              _nutritionField(
                'Salt (g)',
                (v) => _salt = double.tryParse(v ?? ''),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Submit to Open Food Facts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionField(String label, FormFieldSetter<String> onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onSaved: onSaved,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider) as OpenFoodFactsApi;
    final product = Product(
      barcode: widget.barcode,
      name: _name,
      brand: _brand,
      category: _category,
      ingredients: _ingredients,
      energyKcal: _energy,
      proteinG: _protein,
      carbsG: _carbs,
      fatG: _fat,
      fiberG: _fiber,
      saltG: _salt,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
    );

    final success = await api.submitProduct(product);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(product); // return the product to the caller
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Check your connection.'),
          ),
        );
      }
    }
  }
}
