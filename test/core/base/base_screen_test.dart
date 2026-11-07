// Test notifiers expose a hook (completer / failOnce) so tests can drive them.
// ignore_for_file: riverpod_lint/avoid_public_notifier_properties

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_error_view.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';

import '../../helpers/test_app.dart';

/// Page data the test resolves by hand through [completer].
class _DataNotifier extends AsyncNotifier<String> {
  late Completer<String> completer;

  @override
  Future<String> build() => (completer = Completer<String>()).future;
}

final _data = AsyncNotifierProvider<_DataNotifier, String>(_DataNotifier.new);

class _TestScreen extends BaseScreen {
  const _TestScreen();

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: const Text('Title'));

  @override
  Widget? floatingActionButton(BuildContext context, WidgetRef ref) =>
      const FloatingActionButton(onPressed: null, child: Icon(Icons.add));

  @override
  Widget body(BuildContext context, WidgetRef ref) => asyncBody(
    ref.watch(_data),
    onRetry: () => ref.invalidate(_data),
    data: (value) => Text('data: $value'),
  );
}

void main() {
  setUpAll(setUpTestConfig);

  testWidgets('renders hooks and the shared loading widget while loading', (tester) async {
    await pumpTestApp(tester, const _TestScreen());

    expect(find.text('Title'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(AppLoading), findsOneWidget);
  });

  testWidgets('renders data', (tester) async {
    await pumpTestApp(tester, const _TestScreen());
    final element = tester.element(find.byType(_TestScreen));
    ProviderScope.containerOf(element).read(_data.notifier).completer.complete('hello');
    await tester.pump();

    expect(find.text('data: hello'), findsOneWidget);
  });

  testWidgets('renders the shared error view with retry, localized', (tester) async {
    await pumpTestApp(tester, const _TestScreen());
    final element = tester.element(find.byType(_TestScreen));
    ProviderScope.containerOf(element)
        .read(_data.notifier)
        .completer
        .completeError(const NotFoundException());
    await tester.pump();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text("We couldn't find what you were looking for."), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);
  });
}
