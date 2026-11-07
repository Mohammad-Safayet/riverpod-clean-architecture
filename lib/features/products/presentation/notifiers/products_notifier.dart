import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/repositories/product_repository.dart';

part 'gen/products_notifier.g.dart';

@riverpod
class ProductsNotifier extends _$ProductsNotifier with PaginatedNotifier<ProductModel> {
  @override
  Future<PagingState<ProductModel>> build() => loadFirstPage();

  @override
  Future<PageResult<ProductModel>> fetchPage(int page, int pageSize) =>
      ref.read(productRepositoryProvider).getProducts(page: page, pageSize: pageSize);
}
