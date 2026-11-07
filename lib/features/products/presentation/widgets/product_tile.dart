import 'package:flutter/material.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_network_image.dart';
import 'package:riverpod_clean_architecture/features/products/data/models/product_model.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.onTap});

  final ProductModel product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppValues.paddingSmall),
          child: Row(
            children: [
              AppNetworkImage(
                product.thumbnail,
                width: 72,
                height: 72,
                borderRadius: AppValues.radiusSmall,
              ),
              const SizedBox(width: AppValues.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: context.textStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(product.category, style: context.textStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.productPrice(product.price.toStringAsFixed(2)),
                      style: context.textStyles.body.copyWith(color: context.colors.primary),
                    ),
                  ],
                ),
              ),
              Text(
                context.l10n.productRating(product.rating.toStringAsFixed(1)),
                style: context.textStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
