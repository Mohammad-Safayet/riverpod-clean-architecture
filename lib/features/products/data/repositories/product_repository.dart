import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/sources/product_remote_source.dart';

part 'gen/product_repository.g.dart';

/// Lite feature: concrete repository, no interface. Still the only thing the
/// notifiers talk to, so caching/offline can be added here later (or promote the
/// feature to full: see docs/architecture/layers.md).
class ProductRepository {
  ProductRepository(this._remote);

  final ProductRemoteSource _remote;

  Future<PageResult<ProductModel>> getProducts({required int page, required int pageSize}) async {
    final skip = (page - AppValues.firstPage) * pageSize;
    final res = await _remote.getProducts(skip: skip, limit: pageSize);
    return PageResult(items: res.products, hasMore: res.skip + res.products.length < res.total);
  }

  Future<ProductModel> getProduct(int id) => _remote.getProduct(id);
}

@riverpod
ProductRepository productRepository(Ref ref) =>
    ProductRepository(ref.watch(productRemoteSourceProvider));
