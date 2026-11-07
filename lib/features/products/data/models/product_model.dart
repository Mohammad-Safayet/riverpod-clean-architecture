import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/product_model.freezed.dart';
part 'gen/product_model.g.dart';

/// Lite feature: this API model is used by the UI directly (no domain entity).
@freezed
abstract class ProductModel with _$ProductModel {
  const factory ProductModel({
    required int id,
    required String title,
    @Default('') String description,
    required double price,
    @Default(0) double discountPercentage,
    @Default(0) double rating,
    @Default(0) int stock,
    String? brand,
    @Default('') String category,
    @Default('') String thumbnail,
    @Default([]) List<String> images,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
}
