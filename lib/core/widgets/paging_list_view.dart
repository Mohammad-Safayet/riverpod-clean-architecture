import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception_l10n.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_error_view.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';

/// Infinite list for a `PaginatedNotifier`. Handles first-page loading/error,
/// empty state, pull-to-refresh, loading the next page near the bottom, and the
/// footer loader / retry. Port of the GetX template's `PagingView`.
///
/// ```dart
/// PagingListView<ProductModel>(
///   state: ref.watch(productsProvider),
///   onLoadMore: ref.read(productsProvider.notifier).loadNextPage,
///   onRetryNextPage: ref.read(productsProvider.notifier).retryNextPage,
///   onRefresh: ref.read(productsProvider.notifier).refresh,
///   itemBuilder: (context, product, index) => ProductTile(product: product),
/// )
/// ```
class PagingListView<T> extends StatelessWidget {
  const PagingListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRetryNextPage,
    required this.onRefresh,
    this.separatorBuilder,
    this.padding = const EdgeInsets.all(AppValues.padding),
    this.emptyMessage,
  });

  final AsyncValue<PagingState<T>> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryNextPage;
  final VoidCallback onRefresh;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry padding;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncValue(:final value?) => _list(context, value),
      AsyncError(:final error) => AppErrorView(
        exception: asAppException(error),
        onRetry: onRefresh,
      ),
      // Loading, including a retry after an error.
      _ => const AppLoading(),
    };
  }

  Widget _list(BuildContext context, PagingState<T> paging) {
    if (paging.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(children: [AppEmptyView(message: emptyMessage)]),
      );
    }

    final showFooter = !paging.endOfList;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < AppValues.loadMoreThreshold && paging.canLoadNextPage) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: paging.items.length + (showFooter ? 1 : 0),
          separatorBuilder:
              separatorBuilder ?? (_, _) => const SizedBox(height: AppValues.paddingSmall),
          itemBuilder: (context, index) {
            if (index < paging.items.length) {
              return itemBuilder(context, paging.items[index], index);
            }
            return _footer(context, paging);
          },
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, PagingState<T> paging) {
    if (paging.nextPageError case final error?) {
      return Padding(
        padding: const EdgeInsets.all(AppValues.padding),
        child: Column(
          children: [
            Text(error.localizedMessage(context.l10n), style: context.textStyles.caption),
            TextButton(onPressed: onRetryNextPage, child: Text(context.l10n.actionRetry)),
          ],
        ),
      );
    }
    // Short first page that doesn't fill the screen never scrolls, so ask here too.
    if (paging.canLoadNextPage) WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
    return const Padding(padding: EdgeInsets.all(AppValues.padding), child: AppLoading(size: 24));
  }

  Future<void> _refresh() async => onRefresh();
}
