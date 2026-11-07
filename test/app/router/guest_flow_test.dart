import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_clean_architecture/app/app.dart';
import 'package:riverpod_clean_architecture/app/router/app_router.dart';
import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/base/paging.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_user.dart';
import 'package:riverpod_clean_architecture/core/session/sign_in_prompt_notifier.dart';
import 'package:riverpod_clean_architecture/core/storage/storage_providers.dart';
import 'package:riverpod_clean_architecture/core/utils/provider_retry.dart';
import 'package:riverpod_clean_architecture/features/auth/presentation/screens/login_screen.dart';
import 'package:riverpod_clean_architecture/features/products/data/repositories/product_repository.dart';
import 'package:riverpod_clean_architecture/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

/// Starts signed out; [signIn] does what a successful login does to the session.
class _FakeSession extends SessionNotifier {
  @override
  SessionState build() => const SessionState(status: SessionStatus.unauthenticated);

  void signIn() => state = const SessionState(
    status: SessionStatus.authenticated,
    user: SessionUser(id: 1, username: 'u', email: 'u@test.local', fullName: 'U'),
  );
}

/// Guest flows through the real App: router (routes, redirect, refresh on
/// session change) and the sign-in prompt listener.
void main() {
  setUpAll(setUpTestConfig);

  late _FakeSession session;

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    session = _FakeSession();
    final products = _MockProductRepository();
    when(
      () => products.getProducts(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => const PageResult(items: [], hasMore: false));

    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        ...baseOverrides(),
        sharedPreferencesProvider.overrideWithValue(prefs),
        sessionProvider.overrideWith(() => session),
        productRepositoryProvider.overrideWithValue(products),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    return container;
  }

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  Future<ProviderContainer> openLoginFromSettings(WidgetTester tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go(const SettingsRoute().location);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    return container;
  }

  testWidgets('signing in from settings returns to settings, signed in', (tester) async {
    await openLoginFromSettings(tester);

    session.signIn();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('u@test.local'), findsOneWidget);
  });

  testWidgets('closing login returns to settings as a guest', (tester) async {
    await openLoginFromSettings(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });

  testWidgets('a guest action opens login, and signing in returns to that screen', (tester) async {
    final container = await pumpApp(tester);
    expect(location(container), '/products');

    // What requireSignIn() does for a guest.
    container.read(signInPromptProvider.notifier).request();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    session.signIn();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(location(container), '/products');
  });

  testWidgets('closing login opened for a protected screen goes home, not back to login', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go(const LoginRoute(from: '/orders').location);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(location(container), '/products');
  });
}
