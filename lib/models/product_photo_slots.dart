import 'dart:io';

import 'package:pantry_app/models/image_field.dart';

/// An immutable snapshot of the three photo slots in the manual product form.
///
/// Holds the currently selected [File] for the nutrition, ingredients, and
/// product/front photos. A null slot means no photo has been picked. Instances
/// are replaced (never mutated) via [withField], which the
/// [ProductImageService] uses to return new snapshots after each operation.
class ProductPhotoSlots {
  /// Creates a [ProductPhotoSlots] with the given [nutrition], [ingredients],
  /// and [product] files.
  const ProductPhotoSlots({
    this.nutrition,
    this.ingredients,
    this.product,
  });

  /// Creates a [ProductPhotoSlots] where every slot is empty.
  const ProductPhotoSlots.empty()
    : nutrition = null,
      ingredients = null,
      product = null;

  /// The selected nutrition facts table photo, or null when empty.
  final File? nutrition;

  /// The selected ingredients list photo, or null when empty.
  final File? ingredients;

  /// The selected product/front packaging photo, or null when empty.
  final File? product;

  /// Returns the file for [field], or null when that slot is empty.
  File? forField(ImageField field) {
    switch (field) {
      case ImageField.nutrition:
        return nutrition;
      case ImageField.ingredients:
        return ingredients;
      case ImageField.product:
        return product;
    }
  }

  /// Returns a copy of this snapshot with [field] set to [file].
  ProductPhotoSlots withField(ImageField field, File? file) {
    switch (field) {
      case ImageField.nutrition:
        return ProductPhotoSlots(
          nutrition: file,
          ingredients: ingredients,
          product: product,
        );
      case ImageField.ingredients:
        return ProductPhotoSlots(
          nutrition: nutrition,
          ingredients: file,
          product: product,
        );
      case ImageField.product:
        return ProductPhotoSlots(
          nutrition: nutrition,
          ingredients: ingredients,
          product: file,
        );
    }
  }
}
