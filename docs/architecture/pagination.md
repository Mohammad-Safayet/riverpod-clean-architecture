# Pagination

Port of the GetX template's `PagingController` / `PagingView`, as owned code in `core/` (no package).

| Piece | File | Role |
|---|---|---|
| `PageResult<T>` | `core/base/paging.dart` | one page from a repository: `items`, `hasMore` |
| `PagingState<T>` | same | accumulated `items`, `nextPage`, `endOfList`, `isLoadingNextPage`, `nextPageError` |
| `PaginatedNotifier<T>` | same | mixin: `loadFirstPage()`, `loadNextPage()`, `retryNextPage()`, `refresh()` |
| `PagingListView<T>` | `core/widgets/paging_list_view.dart` | the list: first-page loader/error/empty, pull-to-refresh, load more near the bottom, footer loader/retry |

## Use it

Repository returns a `PageResult` (pages start at `AppValues.firstPage` = 1):

```dart
Future<PageResult<ProductModel>> getProducts({required int page, required int pageSize}) async {
  final skip = (page - AppValues.firstPage) * pageSize;
  final res = await _remote.getProducts(skip: skip, limit: pageSize);
  return PageResult(items: res.products, hasMore: res.skip + res.products.length < res.total);
}
```

Notifier:

```dart
@riverpod
class ProductsNotifier extends _$ProductsNotifier with PaginatedNotifier<ProductModel> {
  @override
  Future<PagingState<ProductModel>> build() => loadFirstPage();

  @override
  Future<PageResult<ProductModel>> fetchPage(int page, int pageSize) =>
      ref.read(productRepositoryProvider).getProducts(page: page, pageSize: pageSize);
}
```

Screen:

```dart
final notifier = ref.read(productsProvider.notifier);
return PagingListView<ProductModel>(
  state: ref.watch(productsProvider),
  onLoadMore: notifier.loadNextPage,
  onRetryNextPage: notifier.retryNextPage,
  onRefresh: notifier.refresh,
  itemBuilder: (context, product, index) => ProductTile(product: product),
);
```

## Behaviour

- First page fails → the whole list shows `AppErrorView` with Retry (`refresh`).
- A later page fails → items stay, the footer shows the error and a Retry (`retryNextPage`). No more pages are requested until then.
- `loadNextPage` is a no-op while a page is loading, at the end, or after a page error, so scroll events can call it freely.
- A first page too short to scroll still triggers the next page from the footer.
- Override `pageSize` in the notifier to change it per list; the default is `AppValues.defaultPageSize`.
- Search/filter: make the notifier a family (`build(String query)`), or keep the query in the notifier and call `refresh()` when it changes; debounce input with `core/utils/debouncer.dart`.
