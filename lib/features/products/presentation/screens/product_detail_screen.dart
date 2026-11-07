import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_network_image.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';
import 'package:riverpod_clean_architecture/features/products/presentation/notifiers/product_detail_notifier.dart';

class ProductDetailScreen extends BaseScreen {
  const ProductDetailScreen({super.key, required this.id});

  final int id;

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) {
    final title = ref.watch(productDetailProvider(id)).value?.title ?? '';
    return AppBar(title: Text(title));
  }

  @override
  Widget body(BuildContext context, WidgetRef ref) => asyncBody(
    ref.watch(productDetailProvider(id)),
    onRetry: ref.read(productDetailProvider(id).notifier).retry,
    data: (product) => _Detail(product: product),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final image = product.images.isNotEmpty ? product.images.first : product.thumbnail;
    return ListView(
      padding: const EdgeInsets.all(AppValues.padding),
      children: [
        AspectRatio(aspectRatio: 1, child: AppNetworkImage(image, borderRadius: AppValues.radius)),
        const SizedBox(height: AppValues.padding),
        Text(product.title, style: styles.headline),
        const SizedBox(height: AppValues.paddingSmall),
        Row(
          children: [
            Text(
              l10n.productPrice(product.price.toStringAsFixed(2)),
              style: styles.title.copyWith(color: context.colors.primary),
            ),
            const Spacer(),
            Text(l10n.productRating(product.rating.toStringAsFixed(1)), style: styles.body),
          ],
        ),
        const SizedBox(height: AppValues.paddingSmall),
        Text(l10n.productStock(product.stock), style: styles.caption),
        const SizedBox(height: AppValues.padding),
        Text(product.description, style: styles.body),
      ],
    );
  }
}
