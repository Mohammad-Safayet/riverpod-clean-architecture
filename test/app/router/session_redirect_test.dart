import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/app/router/app_router.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';

void main() {
  String? redirect(SessionStatus status, String location) =>
      sessionRedirect(status, Uri.parse(location));

  test('unknown session waits on splash', () {
    expect(redirect(SessionStatus.unknown, '/products'), '/splash');
    expect(redirect(SessionStatus.unknown, '/splash'), isNull);
  });

  group('guests', () {
    const guest = SessionStatus.unauthenticated;

    test('leave splash for home', () {
      expect(redirect(guest, '/splash'), '/products');
    });

    test('browse public screens and everything under them', () {
      expect(redirect(guest, '/products'), isNull);
      expect(redirect(guest, '/products/5'), isNull);
      expect(redirect(guest, '/settings'), isNull);
      expect(redirect(guest, '/login'), isNull);
      expect(redirect(guest, '/login?from=%2Fproducts%2F5'), isNull);
    });

    test('are sent to login from protected screens, remembering where they were', () {
      expect(redirect(guest, '/orders'), '/login?from=%2Forders');
      expect(redirect(guest, '/orders/7?tab=items'), '/login?from=%2Forders%2F7%3Ftab%3Ditems');
    });

    test('a path that only starts like a public one stays protected', () {
      expect(redirect(guest, '/productsadmin'), '/login?from=%2Fproductsadmin');
    });
  });

  group('signed-in users', () {
    const user = SessionStatus.authenticated;

    test('skip splash and login', () {
      expect(redirect(user, '/splash'), '/products');
      expect(redirect(user, '/login'), '/products');
      expect(redirect(user, '/settings'), isNull);
      expect(redirect(user, '/orders'), isNull);
    });

    test('return to `from` after signing in', () {
      expect(redirect(user, '/login?from=%2Forders%2F7%3Ftab%3Ditems'), '/orders/7?tab=items');
      expect(redirect(user, '/login?from=%2Fproducts%2F5'), '/products/5');
    });

    test('ignore a `from` that is off-app or would loop', () {
      expect(redirect(user, '/login?from=https%3A%2F%2Fevil.com'), '/products');
      expect(redirect(user, '/login?from=%2F%2Fevil.com'), '/products');
      expect(redirect(user, '/login?from=%2Flogin'), '/products');
      expect(redirect(user, '/login?from=%2Fsplash'), '/products');
    });
  });
}
