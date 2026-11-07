import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';

part 'gen/products_page_model.freezed.dart';
part 'gen/products_page_model.g.dart';

/// DummyJSON list envelope: `{products, total, skip, limit}`.
@freezed
abstract class ProductsPageModel with _$ProductsPageModel {
  const factory ProductsPageModel({
    required List<ProductModel> products,
    required int total,
    required int skip,
    required int limit,
  }) = _ProductsPageModel;

  factory ProductsPageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductsPageModelFromJson(json);
}
