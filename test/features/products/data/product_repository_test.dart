import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/products_page_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/repositories/product_repository.dart';
import 'package:riverpod_clean_architecture/features/products/data/sources/product_remote_source.dart';

class _MockRemote extends Mock implements ProductRemoteSource {}

ProductModel product(int id) => ProductModel(id: id, title: 'P$id', price: 1);

void main() {
  late _MockRemote remote;
  late ProductRepository repository;

  setUp(() {
    remote = _MockRemote();
    repository = ProductRepository(remote);
  });

  test('converts page number to skip and reports more pages', () async {
    when(() => remote.getProducts(skip: 20, limit: 20)).thenAnswer(
      (_) async =>
          ProductsPageModel(products: List.generate(20, product), total: 100, skip: 20, limit: 20),
    );

    final page = await repository.getProducts(page: 2, pageSize: 20);

    expect(page.items, hasLength(20));
    expect(page.hasMore, isTrue);
  });

  test('last page has no more', () async {
    when(() => remote.getProducts(skip: 80, limit: 20)).thenAnswer(
      (_) async =>
          ProductsPageModel(products: List.generate(20, product), total: 100, skip: 80, limit: 20),
    );

    final page = await repository.getProducts(page: 5, pageSize: 20);

    expect(page.hasMore, isFalse);
  });
}
