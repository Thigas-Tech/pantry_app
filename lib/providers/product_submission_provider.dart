import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_submission_state.dart';
import 'package:pantry_app/providers/api_service_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_submission_service.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provider for [ProductSubmissionNotifier].
final productSubmissionNotifierProvider =
    NotifierProvider<ProductSubmissionNotifier, ProductSubmissionState>(
      ProductSubmissionNotifier.new,
    );

/// Provider for [ProductSubmissionService].
///
/// Kept in this file so the notifier and the raw service share one home.
final productSubmissionServiceProvider = Provider<ProductSubmissionService>(
  (ref) {
    final db = ref.watch(databaseProvider);
    final api = ref.watch(apiServiceProvider);
    return ProductSubmissionService(db: db, api: api);
  },
);

/// Durable, observable product submission state.
///
/// Holds the single [ProductSubmissionState] for the current submission and
/// survives navigation away from the manual-entry form because the notifier is
/// not autoDisposed. Screens observe [ProductSubmissionNotifier.build] to
/// render progress, and call [submit] (or [submit] with retry: true) instead
/// of launching the raw service, so duplicate concurrent submissions for the
/// same barcode are prevented.
class ProductSubmissionNotifier extends Notifier<ProductSubmissionState> {
  /// Barcodes currently being submitted, used to reject duplicates.
  final Set<String> _inFlight = <String>{};

  /// Returns the initial (idle) submission state.
  @override
  ProductSubmissionState build() => const ProductSubmissionState();

  /// True while any product submission is running.
  bool get isSubmitting => _inFlight.isNotEmpty;

  /// Submits [product], updating [ProductSubmissionNotifier.build] at every
  /// step. When [retry] is true the state briefly reports
  /// [SubmissionStep.retrying] before the real steps.
  ///
  /// Returns the final [Product] persisted by the service. When a submission
  /// for the same barcode is already running, returns [product] unchanged
  /// with a pending status so callers never start a duplicate.
  Future<Product> submit(Product product, {bool retry = false}) async {
    if (_inFlight.contains(product.barcode)) {
      logWarning('Submission already in progress for ${product.barcode}');
      return product.copyWith(submissionStatus: productSubmissionPending);
    }
    _inFlight.add(product.barcode);
    state = ProductSubmissionState(
      barcode: product.barcode,
      step: retry ? SubmissionStep.retrying : SubmissionStep.checking,
    );
    try {
      final service = ref.read(productSubmissionServiceProvider);
      final result = await service.submitProduct(
        product,
        onProgress: (progress) => state = progress,
      );
      state = _terminalStateFor(result);
      return result;
    } on SubmissionAlreadyInProgressException catch (e) {
      logWarning('Submission already in progress for ${e.barcode}');
      return product.copyWith(submissionStatus: productSubmissionPending);
    } on Object catch (e) {
      logError('Submission failed for ${product.barcode}: $e');
      state = const ProductSubmissionState(
        step: SubmissionStep.failed,
        errorCategory: SubmissionErrorCategory.network,
      ).copyWith(barcode: product.barcode);
      return product.copyWith(submissionStatus: productSubmissionFailed);
    } finally {
      _inFlight.remove(product.barcode);
    }
  }

  /// Maps a persisted product [result] to its terminal submission step.
  ProductSubmissionState _terminalStateFor(Product result) {
    final step = switch (result.submissionStatus) {
      productSubmissionSubmitted => SubmissionStep.completed,
      productSubmissionPartiallyCompleted => SubmissionStep.partiallyCompleted,
      _ => SubmissionStep.failed,
    };
    return ProductSubmissionState(barcode: result.barcode, step: step);
  }
}
