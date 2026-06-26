import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/dio_provider.dart';
import 'package:pantry_app/services/open_food_facts_api.dart';

final apiServiceProvider = Provider<OpenFoodFactsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenFoodFactsApi(
    dio,
    // TODO(ThiagoAssis): Remove credentials
    userId: 'thiagoassis',
    password: 'H%Mcfp#Y74p\$ucbBUEFP',
  );
});
