// Test notifiers expose a hook (completer / failOnce) so tests can drive them.
// ignore_for_file: riverpod_lint/avoid_public_notifier_properties

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';

/// Pages of 2 items, 3 pages total. Fails page 2 once when [failOnce] is set.
class _NumbersNotifier extends AsyncNotifier<PagingState<int>> with PaginatedNotifier<int> {
  bool failOnce = false;

  @override
  int get pageSize => 2;

  @override
  Future<PagingState<int>> build() => loadFirstPage();

  @override
  Future<PageResult<int>> fetchPage(int page, int pageSize) async {
    if (page == 2 && failOnce) {
      failOnce = false;
      throw const NetworkException();
    }
    final start = (page - 1) * pageSize;
    return PageResult(items: [start, start + 1], hasMore: page < 3);
  }
}

final _provider = AsyncNotifierProvider<_NumbersNotifier, PagingState<int>>(_NumbersNotifier.new);

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer(retry: noProviderRetry));
  tearDown(() => container.dispose());

  test('PagingState.appendPage advances the page and detects the end', () {
    final state = const PagingState<int>()
        .appendPage(const PageResult(items: [1, 2], hasMore: true))
        .appendPage(const PageResult(items: [3], hasMore: false));
    expect(state.items, [1, 2, 3]);
    expect(state.nextPage, 3);
    expect(state.endOfList, isTrue);
    expect(state.canLoadNextPage, isFalse);
  });

  test('loads pages until the end of the list', () async {
    final notifier = container.read(_provider.notifier);
    await container.read(_provider.future);
    await notifier.loadNextPage();
    await notifier.loadNextPage();
    await notifier.loadNextPage(); // no-op past the end

    final state = container.read(_provider).requireValue;
    expect(state.items, [0, 1, 2, 3, 4, 5]);
    expect(state.endOfList, isTrue);
  });

  test('a failed next page keeps items and can be retried', () async {
    final notifier = container.read(_provider.notifier)..failOnce = true;
    await container.read(_provider.future);

    await notifier.loadNextPage();
    var state = container.read(_provider).requireValue;
    expect(state.items, [0, 1]);
    expect(state.nextPageError, isA<NetworkException>());
    expect(state.canLoadNextPage, isFalse);

    await notifier.retryNextPage();
    state = container.read(_provider).requireValue;
    expect(state.items, [0, 1, 2, 3]);
    expect(state.nextPageError, isNull);
  });
}
