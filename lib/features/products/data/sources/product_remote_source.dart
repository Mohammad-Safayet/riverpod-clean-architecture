import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/base/base_remote_source.dart';
import 'package:riverpod_clean_architecture/core/network/api_endpoints.dart';
import 'package:riverpod_clean_architecture/core/network/dio_provider.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/products_page_model.dart';

part 'gen/product_remote_source.g.dart';

class ProductRemoteSource extends BaseRemoteSource {
  ProductRemoteSource(super.dio);

  Future<ProductsPageModel> getProducts({required int skip, required int limit}) => callApi(
    dio.get<dynamic>(ApiEndpoints.products, queryParameters: {'skip': skip, 'limit': limit}),
    (data) => ProductsPageModel.fromJson(data as Map<String, dynamic>),
  );

  Future<ProductModel> getProduct(int id) => callApi(
    dio.get<dynamic>(ApiEndpoints.product(id)),
    (data) => ProductModel.fromJson(data as Map<String, dynamic>),
  );
}

@riverpod
ProductRemoteSource productRemoteSource(Ref ref) =>
    ProductRemoteSource(ref.watch(dioClientProvider));
