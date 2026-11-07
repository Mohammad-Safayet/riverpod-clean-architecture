import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';

/// One page as returned by a repository.
@immutable
class PageResult<T> {
  const PageResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}

/// Everything a paginated list needs. Port of the GetX template's `PagingController`,
/// but immutable so Riverpod can rebuild on change.
@immutable
class PagingState<T> {
  const PagingState({
    this.items = const [],
    this.nextPage = AppValues.firstPage,
    this.endOfList = false,
    this.isLoadingNextPage = false,
    this.nextPageError,
  });

  final List<T> items;
  final int nextPage;
  final bool endOfList;
  final bool isLoadingNextPage;

  /// Set when loading a *further* page failed. The first page's error is the
  /// notifier's own `AsyncError` instead.
  final AppException? nextPageError;

  bool get canLoadNextPage => !isLoadingNextPage && !endOfList && nextPageError == null;

  PagingState<T> appendPage(PageResult<T> page) => PagingState(
    items: [...items, ...page.items],
    nextPage: nextPage + 1,
    endOfList: !page.hasMore,
  );

  PagingState<T> copyWith({
    bool? isLoadingNextPage,
    AppException? nextPageError,
    bool clearNextPageError = false,
  }) => PagingState(
    items: items,
    nextPage: nextPage,
    endOfList: endOfList,
    isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
    nextPageError: clearNextPageError ? null : nextPageError ?? this.nextPageError,
  );
}

/// Mix into an `@riverpod` AsyncNotifier whose state is `PagingState<T>`:
///
/// ```dart
/// @riverpod
/// class ProductsNotifier extends _$ProductsNotifier with PaginatedNotifier<ProductModel> {
///   @override
///   Future<PagingState<ProductModel>> build() => loadFirstPage();
///
///   @override
///   Future<PageResult<ProductModel>> fetchPage(int page, int pageSize) =>
///       ref.read(productRepositoryProvider).getProducts(page: page, pageSize: pageSize);
/// }
/// ```
///
/// Pair with `PagingListView` in the screen.
mixin PaginatedNotifier<T> {
  Ref get ref;
  AsyncValue<PagingState<T>> get state;
  set state(AsyncValue<PagingState<T>> value);

  int get pageSize => AppValues.defaultPageSize;

  /// Fetch one page. [page] starts at [AppValues.firstPage].
  Future<PageResult<T>> fetchPage(int page, int pageSize);

  Future<PagingState<T>> loadFirstPage() async =>
      PagingState<T>().appendPage(await fetchPage(AppValues.firstPage, pageSize));

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || state.isLoading || !current.canLoadNextPage) return;

    state = AsyncData(current.copyWith(isLoadingNextPage: true));
    try {
      final page = await fetchPage(current.nextPage, pageSize);
      if (ref.mounted) state = AsyncData(current.appendPage(page));
    } on AppException catch (e) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingNextPage: false, nextPageError: e));
      }
    }
  }

  /// Clear the next-page error and try that page again.
  Future<void> retryNextPage() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearNextPageError: true));
    await loadNextPage();
  }

  /// Pull-to-refresh: rebuilds from page one.
  void refresh() => ref.invalidateSelf();
}
