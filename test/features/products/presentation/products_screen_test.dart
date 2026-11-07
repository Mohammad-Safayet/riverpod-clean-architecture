import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_error_view.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/data/repositories/product_repository.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/screens/products_screen.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/widgets/product_tile.dart';

import '../../../helpers/test_app.dart';

class _MockRepository extends Mock implements ProductRepository {}

void main() {
  setUpAll(setUpTestConfig);

  late _MockRepository repository;
  setUp(() => repository = _MockRepository());

  Future<void> pump(WidgetTester tester) => pumpTestApp(
    tester,
    const ProductsScreen(),
    overrides: [productRepositoryProvider.overrideWithValue(repository)],
  );

  testWidgets('shows the first page of products', (tester) async {
    when(() => repository.getProducts(page: 1, pageSize: any(named: 'pageSize'))).thenAnswer(
      (_) async => PageResult(
        items: [for (var i = 1; i <= 3; i++) ProductModel(id: i, title: 'Product $i', price: 9.99)],
        hasMore: false,
      ),
    );

    await pump(tester);
    await tester.pump();

    expect(find.byType(ProductTile), findsNWidgets(3));
    expect(find.text('Product 1'), findsOneWidget);
  });

  testWidgets('shows the error view when the first page fails', (tester) async {
    when(() => repository.getProducts(page: 1, pageSize: any(named: 'pageSize')))
        .thenThrow(const NoInternetException());

    await pump(tester);
    await tester.pump();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
