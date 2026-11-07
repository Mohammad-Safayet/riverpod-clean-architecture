import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/repositories/product_repository.dart';

part 'gen/product_detail_notifier.g.dart';

@riverpod
class ProductDetailNotifier extends _$ProductDetailNotifier {
  @override
  Future<ProductModel> build(int id) => ref.watch(productRepositoryProvider).getProduct(id);

  void retry() => ref.invalidateSelf();
}
