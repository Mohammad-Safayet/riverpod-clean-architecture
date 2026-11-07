import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/widgets/paging_list_view.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/notifiers/products_notifier.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/widgets/product_tile.dart';

class ProductsScreen extends BaseScreen {
  const ProductsScreen({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.productsTitle));

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productsProvider.notifier);
    return PagingListView<ProductModel>(
      state: ref.watch(productsProvider),
      onLoadMore: notifier.loadNextPage,
      onRetryNextPage: notifier.retryNextPage,
      onRefresh: notifier.refresh,
      itemBuilder: (context, product, _) => ProductTile(
        product: product,
        onTap: () => ProductDetailRoute(id: product.id).go(context),
      ),
    );
  }
}
