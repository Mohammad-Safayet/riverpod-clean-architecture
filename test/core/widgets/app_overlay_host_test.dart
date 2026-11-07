import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception.dart';
import 'package:riverpod_clean_architecture/core/messages/app_messenger.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';
import 'package:riverpod_clean_architecture/core/widgets/offline_banner.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(setUpTestConfig);

  const page = Scaffold(body: Text('page'));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.text('page')));

  testWidgets('shows the offline banner when offline', (tester) async {
    await pumpTestApp(tester, page, online: false);
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('no banner when online', (tester) async {
    await pumpTestApp(tester, page);
    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('global loader follows GlobalLoading', (tester) async {
    await pumpTestApp(tester, page);
    final loading = containerOf(tester).read(globalLoadingProvider.notifier);

    loading.show();
    await tester.pump();
    expect(find.byType(AppLoadingOverlay), findsOneWidget);

    loading.hide();
    await tester.pump();
    expect(find.byType(AppLoadingOverlay), findsNothing);
  });

  testWidgets('error messages show once as a localized snackbar', (tester) async {
    await pumpTestApp(tester, page);
    containerOf(tester)
        .read(appMessengerProvider.notifier)
        .showError(const RequestTimeoutException());
    await tester.pump();

    expect(find.text('The request took too long. Please try again.'), findsOneWidget);
  });
}
