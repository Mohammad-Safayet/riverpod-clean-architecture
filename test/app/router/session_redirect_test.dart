import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_clean_architecture/app/router/app_router.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';

void main() {
  test('unknown session waits on splash', () {
    expect(sessionRedirect(SessionStatus.unknown, '/products'), '/splash');
    expect(sessionRedirect(SessionStatus.unknown, '/splash'), isNull);
  });

  test('signed-out users can only see login', () {
    expect(sessionRedirect(SessionStatus.unauthenticated, '/products'), '/login');
    expect(sessionRedirect(SessionStatus.unauthenticated, '/login'), isNull);
  });

  test('signed-in users skip splash and login', () {
    expect(sessionRedirect(SessionStatus.authenticated, '/login'), '/products');
    expect(sessionRedirect(SessionStatus.authenticated, '/splash'), '/products');
    expect(sessionRedirect(SessionStatus.authenticated, '/settings'), isNull);
  });
}
