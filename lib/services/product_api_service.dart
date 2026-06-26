import 'package:pantry_app/models/product.dart';

abstract class ProductApiService {
  Future<Product> getByBarcode(String barcode);
}
